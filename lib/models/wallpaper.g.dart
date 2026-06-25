// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallpaper.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WallpaperAdapter extends TypeAdapter<Wallpaper> {
  @override
  final int typeId = 0;

  @override
  Wallpaper read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Wallpaper(
      id: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String,
      url: fields[3] as String,
      category: fields[4] as String,
      resolvedUrl: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Wallpaper obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.url)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.resolvedUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WallpaperAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
