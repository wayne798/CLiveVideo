# CLiveVideo
# iOS端librtmp+h264+aac实现的推流demo。

前段时间研究iOS客户端推流的功能，在网上搜罗了很多，发现现成的demo几乎没有，这个demo是我整理出来的一个版本。
基本实现了客户端的推流功能需求，有需要的同学可以参考一下。采用了三款播放器测试，延时的话用VLC播放大约在10s左右，[ijkplayer](https://github.com/Bilibili/ijkplayer)播放大约5s左右，如果用[kxmovie](https://github.com/kolyvan/kxmovie)播放大约在3s左右。

先上传一版简单的，bug肯定是有的，后续会继续改进、维护。您的一个star是我最大的鼓励。

#demo说明

1、音视频都是软编码，基于librtmp + h264 + aac 实现。

2、支持前、后摄像头的切换。

3、支持视频的开始、暂停。

![image1](https://github.com/wayne798/CLiveVideo/blob/master/CLiveVideo/CLiveVideo/img1.PNG)

![image2](https://github.com/wayne798/CLiveVideo/blob/master/CLiveVideo/CLiveVideo/img2.PNG)

![image2](https://github.com/wayne798/CLiveVideo/blob/master/CLiveVideo/CLiveVideo/img3.png)

![image2](https://github.com/wayne798/CLiveVideo/blob/master/CLiveVideo/CLiveVideo/img4.png)

#PS
如果有同学需要硬编码的推流demo，请移步runner365同学的SDK。
https://github.com/runner365/LiveVideoCoreSDK
