import 'dart:io';

/// 云盘写入未完成文件的后缀（完成后会替换为正式文件名）。
abstract final class ResumableTransferPaths {
  ResumableTransferPaths._();

  static const cloudPartialSuffix = '.fastsend.part';
}

/// 局域网与云盘共用的断点续传约定（HTTP 头、校验与文件打开方式）。
abstract final class ResumableTransferHeaders {
  /// 本次请求体从源文件的该字节偏移开始（0 表示从头传）。
  static const resumeOffset = 'X-Resume-Offset';
}

/// 断点续传参数不合法或与磁盘状态不一致。
class ResumableTransferException implements Exception {
  ResumableTransferException(this.message);
  final String message;

  @override
  String toString() => 'ResumableTransferException: $message';
}

/// 计算剩余待传字节数。
int resumableRemainingBytes({required int totalSize, required int resumeOffset}) {
  if (resumeOffset < 0 || resumeOffset > totalSize) {
    throw ResumableTransferException('resumeOffset 越界');
  }
  return totalSize - resumeOffset;
}

/// 接收端：根据 [declaredOffset] 打开目标文件写入流。
/// - offset 0：截断新建
/// - offset >0：要求文件已存在且当前长度等于 offset，否则抛错
Future<IOSink> openReceiverSinkForResume({
  required File targetFile,
  required int declaredOffset,
  required int declaredTotalSize,
}) async {
  if (declaredTotalSize < 0) {
    throw ResumableTransferException('无效的 totalSize');
  }
  if (declaredOffset < 0 || declaredOffset > declaredTotalSize) {
    throw ResumableTransferException('无效的 resumeOffset');
  }

  await targetFile.parent.create(recursive: true);

  if (declaredOffset == 0) {
    return targetFile.openWrite(mode: FileMode.write);
  }

  if (!await targetFile.exists()) {
    throw ResumableTransferException('续传需要已存在的部分文件');
  }
  final len = await targetFile.length();
  if (len != declaredOffset) {
    throw ResumableTransferException(
      '续传偏移与磁盘长度不一致: 声明 $declaredOffset，实际 $len',
    );
  }
  return targetFile.openWrite(mode: FileMode.append);
}

/// 将 [stream] 写入 [sink]，并在每处理约 [checkCancelEveryBytes] 字节时调用 [shouldCancel]。
Future<void> pumpStreamWithCancelChecks({
  required Stream<List<int>> stream,
  required IOSink sink,
  int checkCancelEveryBytes = 256 * 1024,
  bool Function()? shouldCancel,
}) async {
  var sinceCheck = 0;
  await for (final chunk in stream) {
    if (shouldCancel != null &&
        shouldCancel() == true) {
      await sink.close();
      throw ResumableTransferException('传输已取消');
    }
    sink.add(chunk);
    sinceCheck += chunk.length;
    if (sinceCheck >= checkCancelEveryBytes) {
      sinceCheck = 0;
      if (shouldCancel != null && shouldCancel() == true) {
        await sink.close();
        throw ResumableTransferException('传输已取消');
      }
    }
  }
  await sink.close();
}
