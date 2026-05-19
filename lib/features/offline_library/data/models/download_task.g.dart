// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadTaskAdapter extends TypeAdapter<DownloadTask> {
  @override
  final int typeId = 13;

  @override
  DownloadTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadTask(
      id: fields[0] as String,
      url: fields[1] as String,
      localPath: fields[2] as String,
      fileType: fields[3] as String,
      storyId: fields[4] as String,
      status: fields[5] as DownloadTaskStatus,
      retryCount: fields[6] as int,
      bytesDownloaded: fields[7] as int,
      totalBytes: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadTask obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.localPath)
      ..writeByte(3)
      ..write(obj.fileType)
      ..writeByte(4)
      ..write(obj.storyId)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.bytesDownloaded)
      ..writeByte(8)
      ..write(obj.totalBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadTaskStatusAdapter extends TypeAdapter<DownloadTaskStatus> {
  @override
  final int typeId = 12;

  @override
  DownloadTaskStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DownloadTaskStatus.pending;
      case 1:
        return DownloadTaskStatus.downloading;
      case 2:
        return DownloadTaskStatus.complete;
      case 3:
        return DownloadTaskStatus.failed;
      default:
        return DownloadTaskStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, DownloadTaskStatus obj) {
    switch (obj) {
      case DownloadTaskStatus.pending:
        writer.writeByte(0);
        break;
      case DownloadTaskStatus.downloading:
        writer.writeByte(1);
        break;
      case DownloadTaskStatus.complete:
        writer.writeByte(2);
        break;
      case DownloadTaskStatus.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadTaskStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
