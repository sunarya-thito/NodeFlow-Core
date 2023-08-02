import 'dart:typed_data';

class DataInputStream {
  final ByteData data;

  const DataInputStream(this.data);

  DataInputStream.fromList(List<int> list) : data = ByteData.view(Uint8List.fromList(list).buffer);

  int readInt() {
    return data.getInt32(0, Endian.big);
  }

  double readDouble() {
    return data.getFloat64(0, Endian.big);
  }

  bool readBool() {
    return data.getInt8(0) == 1;
  }

  int readByte() {
    return data.getInt8(0);
  }

  int readUnsignedByte() {
    return data.getUint8(0);
  }

  int readShort() {
    return data.getInt16(0, Endian.big);
  }

  int readUnsignedShort() {
    return data.getUint16(0, Endian.big);
  }

  int readLong() {
    return data.getInt64(0, Endian.big);
  }

  int readUnsignedLong() {
    return data.getUint64(0, Endian.big);
  }

  int readChar() {
    return data.getUint16(0, Endian.big);
  }

  String readUTF() {
    int length = readUnsignedShort();
    return String.fromCharCodes(data.buffer.asUint8List(0, length));
  }
}
