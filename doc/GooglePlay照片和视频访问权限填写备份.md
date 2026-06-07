# Google Play 照片和视频访问权限填写备份

适用页面：Google Play Console -> 检查发布版本 -> 照片和视频访问权限。

触发权限：

- `android.permission.READ_MEDIA_IMAGES`
- `android.permission.READ_MEDIA_VIDEO`

## 读取媒体图片

可填写：

```text
EteDrop 是本地文件传输应用。用户可在应用中选择本机图片并发送给自己的其他设备或局域网内指定设备；应用只在用户主动选择和传输时读取图片，不用于广告、分析或第三方共享。
```

## 读取媒体视频

可填写：

```text
EteDrop 是本地文件传输应用。用户可在应用中选择本机视频并发送给自己的其他设备或局域网内指定设备；应用只在用户主动选择和传输时读取视频，不用于广告、分析或第三方共享。
```

## 注意事项

Google Play 对 `READ_MEDIA_IMAGES` 和 `READ_MEDIA_VIDEO` 的要求是：必须证明这是应用核心功能中持续或频繁需要的照片/视频访问。

如果应用只是偶尔选择图片或视频，Google 建议改用 Android Photo Picker，并从提交版本里移除这两个权限；否则可能审核不通过。

当前 EteDrop 的申报理由应围绕“本地文件传输、用户主动选择、发送到用户指定设备、不做广告/分析/第三方共享”来写。

官方参考：

- https://support.google.com/googleplay/android-developer/answer/9888170
- https://support.google.com/googleplay/android-developer/answer/15800983
