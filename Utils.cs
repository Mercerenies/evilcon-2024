using System;
using System.Collections.Generic;

namespace Utils {
  public static class ExtensionMethods {
    public static V GetOrAdd<K, V>(this IDictionary<K, V> dict, K key, Func<V> factory) {
      if (dict.TryGetValue(key, out V? value)) {
        return value;
      }
      value = factory();
      dict.Add(key, value);
      return value;
    }

    public static V GetOrElse<K, V>(this IDictionary<K, V> dict, K key, V defaultValue) {
      if (dict.TryGetValue(key, out V? value)) {
        return value;
      } else {
        return defaultValue;
      }
    }

    public static V? GetOrElse<K, V>(this IDictionary<K, V> dict, K key) {
      if (dict.TryGetValue(key, out V? value)) {
        return value;
      } else {
        return default(V);
      }
    }
  }
}
