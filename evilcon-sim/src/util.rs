
use std::iter::Peekable;
use std::cmp::Ordering;

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
pub fn skip_while<I, F>(iter: &mut Peekable<I>, mut cond: F)
where I: Iterator,
      F: FnMut(&I::Item) -> bool {
  while let Some(next) = iter.peek() && cond(next) {
    iter.next().unwrap();
  }
}

/// Sorts the list using an unstable quicksort algorithm. If the
/// comparator ever fails, the sort fails with the same error, and the
/// slice is left in an unspecified order.
pub fn try_sort_by<F, T, E>(arr: &mut [T], mut cmp: F) -> Result<(), E>
where F: FnMut(&T, &T) -> Result<Ordering, E> {
  fn quicksort_impl<F, T, E>(arr: &mut [T], cmp: &mut F) -> Result<(), E>
  where F: FnMut(&T, &T) -> Result<Ordering, E> {
    if arr.len() <= 1 {
      return Ok(()); // Base case
    }
    let pivot = 0;
    let mut dest_i = 1;
    for i in 1..arr.len() {
      if cmp(&arr[i], &arr[pivot])? == Ordering::Less {
        arr.swap(i, dest_i);
        dest_i += 1;
      }
    }
    arr.swap(dest_i - 1, pivot);
    quicksort_impl(&mut arr[..dest_i - 1], cmp)?;
    quicksort_impl(&mut arr[dest_i..], cmp)
  }

  quicksort_impl(arr, &mut cmp)
}

/// `try_reduce` from nightly, but in stable.
pub fn try_reduce<I, E, F>(iter: &mut I, f: F) -> Result<Option<I::Item>, E>
where I: Iterator,
      F: FnMut(I::Item, I::Item) -> Result<I::Item, E> {
  let Some(first) = iter.next() else {
    return Ok(None);
  };
  iter.try_fold(first, f).map(Some)
}

pub fn clamp<T: Ord>(val: T, min: T, max: T) -> T {
  if val < min { min } else if val > max { max } else { val }
}

#[cfg(test)]
mod tests {
  use super::*;

  #[derive(Debug, PartialEq, Eq)]
  struct CmpError;

  #[test]
  fn test_try_sort_infallible() {
    let mut arr = [9, 6, 7, 5, 8, 4, 3, 1, 2, 0];
    try_sort_by(&mut arr, |a, b| Ok::<_, ()>(a.cmp(b))).unwrap();
    assert_eq!(&arr, &[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
  }

  #[test]
  fn test_try_sort_fallible() {
    let mut arr = [9, 6, 7, 5, 8, 4, 3, 1, 2, 0];
    let err = try_sort_by(&mut arr, |_, _| Err(CmpError)).unwrap_err();
    assert_eq!(err, CmpError);
  }
}
