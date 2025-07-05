// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 1;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      themeMode: fields[0] as ThemeMode,
      editorTheme: fields[1] as String,
      fontSize: fields[2] as double,
      showLineNumbers: fields[3] as bool,
      wordWrap: fields[4] as bool,
      defaultViewMode: fields[5] as String,
      autoSave: fields[6] as bool,
      autoSaveInterval: fields[7] as int,
      livePreview: fields[8] as bool,
      language: fields[9] as String,
      splitRatio: fields[10] as double,
      enableSpellCheck: fields[11] as bool,
      enableLinting: fields[12] as bool,
      enableAutoComplete: fields[13] as bool,
      tabSize: fields[14] as int,
      useSpacesForTab: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.editorTheme)
      ..writeByte(2)
      ..write(obj.fontSize)
      ..writeByte(3)
      ..write(obj.showLineNumbers)
      ..writeByte(4)
      ..write(obj.wordWrap)
      ..writeByte(5)
      ..write(obj.defaultViewMode)
      ..writeByte(6)
      ..write(obj.autoSave)
      ..writeByte(7)
      ..write(obj.autoSaveInterval)
      ..writeByte(8)
      ..write(obj.livePreview)
      ..writeByte(9)
      ..write(obj.language)
      ..writeByte(10)
      ..write(obj.splitRatio)
      ..writeByte(11)
      ..write(obj.enableSpellCheck)
      ..writeByte(12)
      ..write(obj.enableLinting)
      ..writeByte(13)
      ..write(obj.enableAutoComplete)
      ..writeByte(14)
      ..write(obj.tabSize)
      ..writeByte(15)
      ..write(obj.useSpacesForTab);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
