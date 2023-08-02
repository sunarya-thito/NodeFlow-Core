class NamedDelta<K, V> {
  final String name;
  final Map<K, V> delta;

  NamedDelta(this.name, this.delta);
}

class DeltaMap<K, V> {
  final Map<K, V> _original;
  final List<NamedDelta<K, V>> _deltas;
  int _maxDeltas;

  DeltaMap(this._original, this._maxDeltas, [this._deltas = const []]);

  void _bakeDelta(int length) {
    Map<K, V> baked = _original;
    for (int i = 0; i < length; i++) {
      applyDelta(baked, _deltas[i].delta);
    }
    _deltas.removeRange(0, length);
  }

  Map<K, V> operator [](int index) {
    // deep copy of original
    Map<K, V> result = deepCopy(_original);
    for (int i = 0; i < index; i++) {
      applyDelta(result, _deltas[i].delta);
    }
    return result;
  }

  List<NamedDelta> get deltas => List.unmodifiable(_deltas);

  void insertData(int index, String name, Map<K, V> newData) {
    insert(index, NamedDelta(name, deltaOf(_original, newData)));
  }

  void insert(int index, NamedDelta<K, V> delta) {
    // discard all deltas after index
    _deltas.removeRange(index, _deltas.length);
    _deltas.add(delta);
    if (_deltas.length > _maxDeltas) {
      _bakeDelta(_deltas.length - _maxDeltas);
    }
  }

  int get length => _deltas.length;

  set maxDeltas(int value) {
    _maxDeltas = value;
    if (_deltas.length > _maxDeltas) {
      _bakeDelta(_deltas.length - _maxDeltas);
    }
  }
}

List<T> deepCopyList<T>(List<T> original) {
  if (T is Map) {
    return original.map((e) => deepCopy(e as Map) as T).toList();
  } else if (T is List<dynamic>) {
    return original.map((e) => deepCopyList(e as List) as T).toList();
  } else {
    return original.map((e) => e).toList();
  }
}

Map<K, V> deepCopy<K, V>(Map<K, V> original) {
  return original.map((key, value) {
    if (value is Map) {
      return MapEntry(key, deepCopy(value) as V);
    } else if (value is List<dynamic>) {
      return MapEntry(key, deepCopyList(value) as V);
    } else {
      return MapEntry(key, value);
    }
  });
}

Map<K, V> deltaOf<K, V>(Map<K, V> original, Map<K, V> modified) {
  Map<K, V> result = {};
  modified.forEach((key, value) {
    if (original[key] != value) {
      if (value is Map && original[key] is Map) {
        result[key] = deltaOf(original[key] as Map, value) as V;
      } else {
        result[key] = value;
      }
    }
  });
  return result;
}

void applyDelta<K, V>(Map<K, V> original, Map<K, V> delta) {
  delta.forEach((key, value) {
    if (value is Map && original[key] is Map) {
      applyDelta(original[key] as Map, value);
    } else {
      original[key] = value;
    }
  });
}
