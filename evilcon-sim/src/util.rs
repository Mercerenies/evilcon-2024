
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
