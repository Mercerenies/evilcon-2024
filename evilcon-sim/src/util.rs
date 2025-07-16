
use std::iter::Peekable;

/// Collects the first `n` elements of the iterator, advancing the
/// iterator to that point. If there are fewer than `n` elements, then
/// all elements are collected.
pub fn take_n<I>(iter: &mut I, n: usize) -> Vec<I::Item>
where I: Iterator {
  let mut vec = Vec::with_capacity(n);
  for _ in 0..n {
    if let Some(x) = iter.next() {
      vec.push(x);
    } else {
      break
    }
  }
  vec
}

/// Drop elements of a peekable iterator while the condition is true.
pub fn drop_while<I, F>(mut iter: Peekable<I>, mut cond: F) -> Peekable<I>
where I: Iterator,
      F: FnMut(&I::Item) -> bool {
  while let Some(next) = iter.peek() && cond(next) {
    iter.next().unwrap();
  }
  iter
}
