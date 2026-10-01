//! 3D version of the agent model.
//!
//! Data layout (all `Real64`, row-major):
//!
//! * `agents`  -- `{n, 7}`: `x, y, z, hx, hy, hz, species` (position in grid units, unit heading)
//! * `trail`   -- `{S, d, h, w}`: one chemo-attractant layer per species
//! * `stim`    -- `{d, h, w}`: external attractant ("food") added to every layer each step
//! * `wall`    -- `{d, h, w}`: nonzero cells are obstacles
//! * `params`  -- `{S, 9}`: as in 2D
//!
//! Each agent has a centre sensor along its heading and a ring of `RING` sensors tilted
//! away from it by the sensor angle. The ring is turned by a random phase every step, so
//! that no direction is preferred. The agent keeps going if the centre smells strongest,
//! turns by the rotation angle towards the strongest ring sensor otherwise, and picks a
//! random ring sensor if the centre smells weakest of all (as the 2D model turns randomly).

use crate::{splitmix, unit, Species};
use rayon::prelude::*;
use std::f64::consts::TAU;
use wolfram_library_link as wll;

const RING: usize = 4;

type V3 = [f64; 3];

#[inline]
fn add(a: V3, b: V3) -> V3 {
    [a[0] + b[0], a[1] + b[1], a[2] + b[2]]
}

#[inline]
fn scale(s: f64, a: V3) -> V3 {
    [s * a[0], s * a[1], s * a[2]]
}

#[inline]
fn cross(a: V3, b: V3) -> V3 {
    [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
}

#[inline]
fn normalize(a: V3) -> V3 {
    let n = (a[0] * a[0] + a[1] * a[1] + a[2] * a[2]).sqrt();
    if n > 0.0 {
        scale(1.0 / n, a)
    } else {
        [1.0, 0.0, 0.0]
    }
}

/// Two unit vectors that, with `h`, form an orthonormal basis.
#[inline]
fn perpendiculars(h: V3) -> (V3, V3) {
    let a = if h[0].abs() < 0.9 { [1.0, 0.0, 0.0] } else { [0.0, 1.0, 0.0] };
    let e1 = normalize(cross(a, h));
    (e1, cross(h, e1))
}

/// `h` tilted by `angle` towards the perpendicular unit vector `u`.
#[inline]
fn tilt(h: V3, u: V3, angle: f64) -> V3 {
    normalize(add(scale(angle.cos(), h), scale(angle.sin(), u)))
}

/// A uniformly random unit vector.
#[inline]
fn random_direction(rng: &mut u64) -> V3 {
    *rng = splitmix(*rng);
    let z = 2.0 * unit(*rng) - 1.0;
    *rng = splitmix(*rng);
    let t = TAU * unit(*rng);
    let r = (1.0 - z * z).max(0.0).sqrt();
    [r * t.cos(), r * t.sin(), z]
}

struct Grid<'a> {
    trail: &'a [f64],
    wall: &'a [f64],
    dims: [usize; 3], // w, h, d
    layers: usize,
    wrap: bool,
    has_walls: bool,
}

impl Grid<'_> {
    /// Cell index for continuous coordinates, or `None` if off-grid / blocked.
    #[inline]
    fn cell(&self, p: V3) -> Option<usize> {
        let mut c = [0usize; 3];
        for k in 0..3 {
            let n = self.dims[k] as f64;
            let v = if self.wrap {
                p[k].rem_euclid(n)
            } else if p[k] < 0.0 || p[k] >= n {
                return None;
            } else {
                p[k]
            };
            c[k] = (v as usize).min(self.dims[k] - 1);
        }
        let [w, h, _] = self.dims;
        let idx = (c[2] * h + c[1]) * w + c[0];
        if self.wall[idx] != 0.0 {
            None
        } else {
            Some(idx)
        }
    }

    /// True if the straight line from `a` to `b` stays out of walls, sampled at roughly
    /// one-cell intervals.
    #[inline]
    fn clear_line(&self, a: V3, b: V3) -> bool {
        if !self.has_walls {
            return true;
        }
        let d = [b[0] - a[0], b[1] - a[1], b[2] - a[2]];
        let steps = (d[0] * d[0] + d[1] * d[1] + d[2] * d[2]).sqrt().ceil().max(1.0) as usize;
        (1..steps).all(|k| self.cell(add(a, scale(k as f64 / steps as f64, d))).is_some())
    }

    /// What species `s` "smells" at a point: its own trail minus a penalty for
    /// everybody else's.
    #[inline]
    fn sense(&self, s: usize, repulsion: f64, p: V3) -> f64 {
        match self.cell(p) {
            None => f64::NEG_INFINITY,
            Some(c) => {
                let n = self.dims[0] * self.dims[1] * self.dims[2];
                let own = self.trail[s * n + c];
                if repulsion == 0.0 || self.layers == 1 {
                    own
                } else {
                    let total: f64 = (0..self.layers).map(|l| self.trail[l * n + c]).sum();
                    own - repulsion * (total - own)
                }
            }
        }
    }
}

pub(crate) fn evolve3d(
    agents: &mut [f64],
    trail: &mut Vec<f64>,
    stim: &[f64],
    wall: &[f64],
    species: &[Species],
    (layers, d, h, w): (usize, usize, usize, usize),
    wrap: bool,
    nsteps: usize,
    seed: u64,
) -> bool {
    let n = w * h * d;
    let mut buf = vec![0.0; trail.len()];
    let mut moved = vec![true; agents.len() / 7];
    let has_walls = wall.iter().any(|&v| v != 0.0);

    for step in 0..nsteps {
        if wll::aborted() {
            return false;
        }
        let step_key = splitmix(seed ^ (step as u64).wrapping_mul(0xD1B5_4A32_D192_ED03));

        // 1. Sense, rotate, move (parallel: trail is read-only here).
        {
            let grid = Grid { trail, wall, dims: [w, h, d], layers, wrap, has_walls };
            agents.par_chunks_mut(7).zip(moved.par_iter_mut()).enumerate().for_each(|(i, (a, ok))| {
                let s = (a[6] as usize).min(layers - 1);
                let sp = &species[s];
                let p = [a[0], a[1], a[2]];
                let mut hd = normalize([a[3], a[4], a[5]]);
                let mut rng = splitmix(step_key ^ (i as u64).wrapping_mul(0x9E37_79B9_7F4A_7C15));

                // Sensors cannot see through walls.
                let probe = |dir: V3| {
                    let q = add(p, scale(sp.sensor_dist, dir));
                    if grid.clear_line(p, q) {
                        grid.sense(s, sp.repulsion, q)
                    } else {
                        f64::NEG_INFINITY
                    }
                };

                let (e1, e2) = perpendiculars(hd);
                rng = splitmix(rng);
                let phase = TAU * unit(rng);
                let ring: [V3; RING] = std::array::from_fn(|k| {
                    let phi = phase + TAU * k as f64 / RING as f64;
                    add(scale(phi.cos(), e1), scale(phi.sin(), e2))
                });
                let fc = probe(hd);
                let fr: [f64; RING] = std::array::from_fn(|k| probe(tilt(hd, ring[k], sp.sensor_angle)));
                let (best, fbest) = fr.iter().copied().enumerate().fold((0, f64::NEG_INFINITY), |acc, (k, v)| {
                    if v > acc.1 { (k, v) } else { acc }
                });

                if fc >= fbest {
                    // keep going straight
                } else if fr.iter().all(|&v| fc < v) {
                    rng = splitmix(rng);
                    let k = ((unit(rng) * RING as f64) as usize).min(RING - 1);
                    hd = tilt(hd, ring[k], sp.rotate);
                } else {
                    hd = tilt(hd, ring[best], sp.rotate);
                }

                // Jitter: a random tilt of up to jitter/2 in a random direction.
                if sp.jitter != 0.0 {
                    let (e1, e2) = perpendiculars(hd);
                    rng = splitmix(rng);
                    let phi = TAU * unit(rng);
                    rng = splitmix(rng);
                    hd = tilt(hd, add(scale(phi.cos(), e1), scale(phi.sin(), e2)), sp.jitter * (unit(rng) - 0.5));
                }

                let q = add(p, scale(sp.step, hd));
                *ok = grid.cell(q).is_some();
                if *ok {
                    for k in 0..3 {
                        let n = [w, h, d][k] as f64;
                        a[k] = if wrap { q[k].rem_euclid(n) } else { q[k] };
                    }
                } else {
                    // Bumped into a wall or edge: stay put, pick a new random heading.
                    hd = random_direction(&mut rng);
                }
                a[3] = hd[0];
                a[4] = hd[1];
                a[5] = hd[2];
            });
        }

        // 2. Deposit (sequential: cheap, and avoids write races). Agents that bumped into
        //    a wall or edge this step do not deposit, so boundaries don't attract.
        for a in agents.chunks(7).zip(&moved).filter(|(_, &ok)| ok).map(|(a, _)| a) {
            let s = (a[6] as usize).min(layers - 1);
            let c = ((a[2] as usize).min(d - 1) * h + (a[1] as usize).min(h - 1)) * w + (a[0] as usize).min(w - 1);
            trail[s * n + c] += species[s].deposit;
        }

        // 3. Diffuse (3x3x3 mean blended with the original), decay, add food.
        //    Rows of length w are processed in parallel; row_id = (layer * d + z) * h + y.
        {
            let src: &[f64] = trail;
            buf.par_chunks_mut(w).enumerate().for_each(|(row_id, out)| {
                let (l, z, y) = (row_id / (d * h), (row_id / h) % d, row_id % h);
                let sp = &species[l];
                let layer = &src[l * n..(l + 1) * n];
                let wrapped = |v: isize, n: usize| -> Option<usize> {
                    if wrap {
                        Some(v.rem_euclid(n as isize) as usize)
                    } else if v < 0 || v >= n as isize {
                        None
                    } else {
                        Some(v as usize)
                    }
                };
                for x in 0..w {
                    let idx = (z * h + y) * w + x;
                    if wall[idx] != 0.0 {
                        out[x] = 0.0;
                        continue;
                    }
                    let mut acc = 0.0;
                    let mut cnt = 0.0;
                    for dz in [-1isize, 0, 1] {
                        let Some(zz) = wrapped(z as isize + dz, d) else { continue };
                        for dy in [-1isize, 0, 1] {
                            let Some(yy) = wrapped(y as isize + dy, h) else { continue };
                            let row = (zz * h + yy) * w;
                            for dx in [-1isize, 0, 1] {
                                let Some(xx) = wrapped(x as isize + dx, w) else { continue };
                                acc += layer[row + xx];
                                cnt += 1.0;
                            }
                        }
                    }
                    let v = layer[idx];
                    let mixed = (1.0 - sp.diffusion) * v + sp.diffusion * acc / cnt;
                    out[x] = (1.0 - sp.decay) * mixed + stim[idx];
                }
            });
        }
        std::mem::swap(trail, &mut buf);
    }
    true
}
