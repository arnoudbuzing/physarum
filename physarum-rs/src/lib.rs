//! Physarum (slime mould) transport-network simulation kernel.
//!
//! This crate contains only the performance-critical inner loop of a
//! multi-species Jones-style agent model. Everything else (setup, presets,
//! rendering, network extraction) lives in the Wolfram Language side of the
//! `Physarum` paclet.
//!
//! Data layout (all `Real64`, row-major):
//!
//! * `agents`  -- `{n, 4}`: `x, y, heading, species` (x, y in grid units, heading in radians)
//! * `trail`   -- `{S, h, w}`: one chemo-attractant layer per species
//! * `stim`    -- `{h, w}`: external attractant ("food") added to every layer each step
//! * `wall`    -- `{h, w}`: nonzero cells are obstacles
//! * `params`  -- `{S, 9}`: per-species
//!   `sensorAngle, sensorDistance, rotationAngle, stepSize, deposit,
//!    decay, diffusion, jitter, repulsion`

use rayon::prelude::*;
use wolfram_library_link::{self as wll, NumericArray};

const NPARAMS: usize = 9;

#[derive(Clone, Copy)]
struct Species {
    sensor_angle: f64,
    sensor_dist: f64,
    rotate: f64,
    step: f64,
    deposit: f64,
    decay: f64,
    diffusion: f64,
    jitter: f64,
    repulsion: f64,
}

impl Species {
    fn from_row(r: &[f64]) -> Self {
        Species {
            sensor_angle: r[0],
            sensor_dist: r[1],
            rotate: r[2],
            step: r[3],
            deposit: r[4],
            decay: r[5],
            diffusion: r[6],
            jitter: r[7],
            repulsion: r[8],
        }
    }
}

/// SplitMix64: small, fast, statistically good enough for agent jitter, and
/// lets every agent draw independent numbers in parallel from (seed, step, id).
#[inline]
fn splitmix(mut z: u64) -> u64 {
    z = z.wrapping_add(0x9E37_79B9_7F4A_7C15);
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58_476D_1CE4_E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D0_49BB_1331_11EB);
    z ^ (z >> 31)
}

#[inline]
fn unit(z: u64) -> f64 {
    (z >> 11) as f64 * (1.0 / (1u64 << 53) as f64)
}

struct Grid<'a> {
    trail: &'a [f64],
    wall: &'a [f64],
    w: usize,
    h: usize,
    layers: usize,
    wrap: bool,
    has_walls: bool,
}

impl Grid<'_> {
    /// Cell index for continuous coordinates, or `None` if off-grid / blocked.
    #[inline]
    fn cell(&self, x: f64, y: f64) -> Option<usize> {
        let (w, h) = (self.w as f64, self.h as f64);
        let (x, y) = if self.wrap {
            (x.rem_euclid(w), y.rem_euclid(h))
        } else if x < 0.0 || y < 0.0 || x >= w || y >= h {
            return None;
        } else {
            (x, y)
        };
        let c = (y as usize).min(self.h - 1) * self.w + (x as usize).min(self.w - 1);
        if self.wall[c] != 0.0 {
            None
        } else {
            Some(c)
        }
    }

    /// True if the straight line from (x0, y0) to (x1, y1) stays out of walls,
    /// sampled at roughly one-pixel intervals.
    #[inline]
    fn clear_line(&self, x0: f64, y0: f64, x1: f64, y1: f64) -> bool {
        if !self.has_walls {
            return true;
        }
        let steps = (x1 - x0).hypot(y1 - y0).ceil().max(1.0) as usize;
        (1..steps).all(|k| {
            let t = k as f64 / steps as f64;
            self.cell(x0 + t * (x1 - x0), y0 + t * (y1 - y0)).is_some()
        })
    }

    /// What species `s` "smells" at a point: its own trail minus a penalty for
    /// everybody else's.
    #[inline]
    fn sense(&self, s: usize, repulsion: f64, x: f64, y: f64) -> f64 {
        match self.cell(x, y) {
            None => f64::NEG_INFINITY,
            Some(c) => {
                let n = self.w * self.h;
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

fn evolve(
    agents: &mut [f64],
    trail: &mut Vec<f64>,
    stim: &[f64],
    wall: &[f64],
    species: &[Species],
    (layers, h, w): (usize, usize, usize),
    wrap: bool,
    nsteps: usize,
    seed: u64,
) -> bool {
    let n = w * h;
    let mut buf = vec![0.0; trail.len()];
    let mut moved = vec![true; agents.len() / 4];
    let has_walls = wall.iter().any(|&v| v != 0.0);

    for step in 0..nsteps {
        if wll::aborted() {
            return false;
        }
        let step_key = splitmix(seed ^ (step as u64).wrapping_mul(0xD1B5_4A32_D192_ED03));

        // 1. Sense, rotate, move (parallel: trail is read-only here).
        {
            let grid = Grid { trail, wall, w, h, layers, wrap, has_walls };
            agents.par_chunks_mut(4).zip(moved.par_iter_mut()).enumerate().for_each(|(i, (a, ok))| {
                let s = (a[3] as usize).min(layers - 1);
                let sp = &species[s];
                let (x, y, mut th) = (a[0], a[1], a[2]);
                let mut rng = splitmix(step_key ^ (i as u64).wrapping_mul(0x9E37_79B9_7F4A_7C15));

                // Sensors cannot see through walls.
                let probe = |ang: f64| {
                    let (sx, sy) = (x + sp.sensor_dist * ang.cos(), y + sp.sensor_dist * ang.sin());
                    if grid.clear_line(x, y, sx, sy) {
                        grid.sense(s, sp.repulsion, sx, sy)
                    } else {
                        f64::NEG_INFINITY
                    }
                };
                let fl = probe(th - sp.sensor_angle);
                let fc = probe(th);
                let fr = probe(th + sp.sensor_angle);

                if fc >= fl && fc >= fr {
                    // keep going straight
                } else if fc < fl && fc < fr {
                    rng = splitmix(rng);
                    th += if unit(rng) < 0.5 { -sp.rotate } else { sp.rotate };
                } else if fl > fr {
                    th -= sp.rotate;
                } else {
                    th += sp.rotate;
                }
                rng = splitmix(rng);
                th += sp.jitter * (unit(rng) - 0.5);

                let (nx, ny) = (x + sp.step * th.cos(), y + sp.step * th.sin());
                *ok = grid.cell(nx, ny).is_some();
                if *ok {
                    a[0] = if wrap { nx.rem_euclid(w as f64) } else { nx };
                    a[1] = if wrap { ny.rem_euclid(h as f64) } else { ny };
                } else {
                    // Bumped into a wall or edge: stay put, pick a new random heading.
                    rng = splitmix(rng);
                    th = std::f64::consts::TAU * unit(rng);
                }
                a[2] = th.rem_euclid(std::f64::consts::TAU);
            });
        }

        // 2. Deposit (sequential: cheap, and avoids write races). Agents that bumped into
        //    a wall or edge this step do not deposit, so boundaries don't attract.
        for a in agents.chunks(4).zip(&moved).filter(|(_, &ok)| ok).map(|(a, _)| a) {
            let s = (a[3] as usize).min(layers - 1);
            let c = (a[1] as usize).min(h - 1) * w + (a[0] as usize).min(w - 1);
            trail[s * n + c] += species[s].deposit;
        }

        // 3. Diffuse (3x3 mean blended with the original), decay, add food.
        {
            let src: &[f64] = trail;
            buf.par_chunks_mut(w).enumerate().for_each(|(row_id, out)| {
                let (l, r) = (row_id / h, row_id % h);
                let sp = &species[l];
                let layer = &src[l * n..(l + 1) * n];
                for c in 0..w {
                    let idx = r * w + c;
                    if wall[idx] != 0.0 {
                        out[c] = 0.0;
                        continue;
                    }
                    let mut acc = 0.0;
                    let mut cnt = 0.0;
                    for dr in [-1isize, 0, 1] {
                        for dc in [-1isize, 0, 1] {
                            let (rr, cc) = (r as isize + dr, c as isize + dc);
                            let (rr, cc) = if wrap {
                                (rr.rem_euclid(h as isize) as usize, cc.rem_euclid(w as isize) as usize)
                            } else if rr < 0 || cc < 0 || rr >= h as isize || cc >= w as isize {
                                continue;
                            } else {
                                (rr as usize, cc as usize)
                            };
                            acc += layer[rr * w + cc];
                            cnt += 1.0;
                        }
                    }
                    let v = layer[idx];
                    let mixed = (1.0 - sp.diffusion) * v + sp.diffusion * acc / cnt;
                    out[c] = (1.0 - sp.decay) * mixed + stim[idx];
                }
            });
        }
        std::mem::swap(trail, &mut buf);
    }
    true
}

/// `PhysarumEvolve[agents, trail, stim, wall, params, wrap, nsteps, seed]`
///
/// Returns a flat vector `Join[Flatten[agents'], Flatten[trail']]`; the Wolfram
/// Language side reshapes it. Returns an empty vector if aborted.
#[wll::export]
fn physarum_evolve(
    agents: &NumericArray<f64>,
    trail: &NumericArray<f64>,
    stim: &NumericArray<f64>,
    wall: &NumericArray<f64>,
    params: &NumericArray<f64>,
    wrap: i64,
    nsteps: i64,
    seed: i64,
) -> NumericArray<f64> {
    let td = trail.dimensions();
    assert!(td.len() == 3, "trail must have rank 3 {{species, h, w}}");
    let (layers, h, w) = (td[0], td[1], td[2]);
    assert!(agents.rank() == 2 && agents.dimensions()[1] == 4, "agents must be {{n, 4}}");
    assert!(stim.flattened_length() == h * w && wall.flattened_length() == h * w, "stim/wall must be {{h, w}}");
    assert!(params.flattened_length() == layers * NPARAMS, "params must be {{species, 9}}");

    let species: Vec<Species> = params.as_slice().chunks(NPARAMS).map(Species::from_row).collect();
    let mut ag = agents.as_slice().to_vec();
    let mut tr = trail.as_slice().to_vec();

    let ok = evolve(
        &mut ag,
        &mut tr,
        stim.as_slice(),
        wall.as_slice(),
        &species,
        (layers, h, w),
        wrap != 0,
        nsteps.max(0) as usize,
        seed as u64,
    );
    if !ok {
        return NumericArray::from_slice(&[]);
    }
    ag.extend_from_slice(&tr);
    NumericArray::from_slice(&ag)
}

/// Required by the kernel's library loader; not generated by the crate.
#[no_mangle]
pub extern "C" fn WolframLibrary_getVersion() -> wll::sys::mint {
    wll::sys::WolframLibraryVersion as wll::sys::mint
}

#[wll::init]
fn init() {}

/// Number of worker threads rayon will use (handy for diagnostics).
#[wll::export]
fn physarum_threads() -> i64 {
    rayon::current_num_threads() as i64
}
