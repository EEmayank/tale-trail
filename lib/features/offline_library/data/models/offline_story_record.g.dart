// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_story_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineStoryRecordAdapter extends TypeAdapter<OfflineStoryRecord> {
  @override
  final int typeId = 11;

  @override
  OfflineStoryRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineStoryRecord(
      storyId: fields[0] as String,
      title: fields[1] as String,
      coverPath: fields[2] as String,
      totalSizeBytes: fields[3] as int,
      downloadStatus: fields[4] as DownloadStatus,
      downloadProgress: fields[5] as double,
      version: fields[6] as int,
      downloadedAt: fields[7] as DateTime?,
      localTreePath: fields[8] as String?,
      localAudioDir: fields[9] as String?,
      localIllustrationDir: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineStoryRecord obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.storyId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.coverPath)
      ..writeByte(3)
      ..write(obj.totalSizeBytes)
      ..writeByte(4)
      ..write(obj.downloadStatus)
      ..writeByte(5)
      ..write(obj.downloadProgress)
      ..writeByte(6)
      ..write(obj.version)
      ..writeByte(7)
      ..write(obj.downloadedAt)
      ..writeByte(8)
      ..write(obj.localTreePath)
      ..writeByte(9)
      ..write(obj.localAudioDir)
      ..writeByte(10)
      ..write(obj.localIllustrationDir);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineStoryRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadStatusAdapter extends TypeAdapter<DownloadStatus> {
  @override
  final int typeId = 10;

  @override
  DownloadStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DownloadStatus.notDownloaded;
      case 1:
        return DownloadStatus.downloading;
      case 2:
        return DownloadStatus.paused;
      case 3:
        return DownloadStatus.complete;
      case 4:
        return DownloadStatus.failed;
      default:
        return DownloadStatus.notDownloaded;
    }
  }

  @override
  void write(BinaryWriter writer, DownloadStatus obj) {
    switch (obj) {
      case DownloadStatus.notDownloaded:
        writer.writeByte(0);
        break;
      case DownloadStatus.downloading:
        writer.writeByte(1);
        break;
      case DownloadStatus.paused:
        writer.writeByte(2);
        break;
      case DownloadStatus.complete:
        writer.writeByte(3);
        break;
      case DownloadStatus.failed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
