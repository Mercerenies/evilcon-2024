
//! Bradley-Terry model.

use std::ops::{Index, IndexMut};

pub const BRADLEY_TERRY_ITERS: usize = 1_000;
pub const LEARNING_RATE: f64 = 0.1;

/// Matrix of win records, as a square matrix. Should be stored in
/// row-major format, so that an entry `(x, y)` is at `y * width + x`.
///
/// This is a pure data structure; no preconditions are validated. In
/// principle, it should be a square matrix of size `width * width`.
#[derive(Debug, Clone)]
pub struct WinMatrix {
  pub width: usize,
  pub data: Vec<u64>,
}

impl Index<(usize, usize)> for WinMatrix {
  type Output = u64;

  fn index(&self, (x, y): (usize, usize)) -> &u64 {
    &self.data[y * self.width + x]
  }
}

impl IndexMut<(usize, usize)> for WinMatrix {
  fn index_mut(&mut self, (x, y): (usize, usize)) -> &mut u64 {
    &mut self.data[y * self.width + x]
  }
}

/// Compute scores given the result of random matchups.
pub fn compute_scores(wins: &WinMatrix) -> Vec<f64> {
  let mut scores = vec![0.0; wins.width];
  for _ in 0..BRADLEY_TERRY_ITERS {
    let gradients = compute_gradients(&scores, wins);
    for i in 0..wins.width {
      scores[i] += LEARNING_RATE * gradients[i];
    }
  }
  scores
}

/// Gradients for Bradley-Terry model function `P(i > j) = e^bi /
/// (e^bi + e^bj)`
pub fn compute_gradients(scores: &[f64], wins: &WinMatrix) -> Vec<f64> {
  let width = wins.width;
  assert!(width == scores.len());

  let mut grads = vec![0.0; width];
  for i in 0..width {
    for j in 0..width {
      if i == j {
        continue;
      }

      let s_i = scores[i];
      let s_j = scores[j];
      let p_ij = (s_i - s_j).exp() / (1.0 + (s_i - s_j).exp()); // logistic (sigmoid)

      let w_ij = wins[(i, j)] as f64;
      let w_ji = wins[(j, i)] as f64;
      let total = w_ij + w_ji;

      if total == 0.0 {
        // No data; skip.
        continue;
      }

      let observed = w_ij / total;
      let error = observed - p_ij;

      // Derivative of sigmoid is `p * (1 - p)`
      let grad = error * p_ij * (1.0 - p_ij);
      grads[i] += grad;
    }
  }
  grads
}
