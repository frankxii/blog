---
slug: thinking-about-sound-effect-management
title: Unity 音效管理引发的思考
authors: frankxii
tags: [Unity, 音效, 反射, 字典]
---

## 起因
最近在看mike的unity教学视频，视频里提到可以把所有音效绑定到一个SoundManager，然后在需要音效的时候直接调这个类，避免物体上挂载太多的AudioSource，基础的写法如下：

```csharp
public class SoundManager : MonoBehaviour
{
    public AudioSource audioSource;
    public static SoundManager instance;

    [SerializeField]
    private AudioClip _playerJumpAudio, _playerHurtAudio, _itemCollectedAudio;

    private void Awake()
    {
        instance = this;
    }

    public void JumpAudio()
    {
        audioSource.clip = _playerJumpAudio;
        audioSource.Play();
    }

    public void HurtAudio()
    {
        audioSource.clip = _playerHurtAudio;
        audioSource.Play();
    }

    public void CollectedAudio()
    {
        audioSource.clip = _itemCollectedAudio;
        audioSource.Play();
    }
}
```
调用如下，通过静态属性绑定实例指针的方式，直接调用类下的播放音效方法。
```csharp
SoundManager.instance.JumpAudio();
```

这样写挺好的，简单，直接，效率高，维护性也不错，唯一缺点是要写太多方法了，如果有100个音频，需要写100个方法，每个方法基本都是同样的代码。所以我就寻思着统一使用一个方法来播放所有绑定的音频。

## 使用字典
首先想着用一个字典来绑定字符串和音频的关系，对外公开PlayAudio方法，通过传入对应音频字符串，然后查找映射来播放音频。
```csharp
private Dictionary<string, AudioClip> _clipMap;

private void Awake()
{
    instance = this;
    _clipMap = new Dictionary<string, AudioClip>()
    {
        {"jump", _playerJumpAudio},
        {"hurt", _playerHurtAudio},
        {"collected", _itemCollectedAudio}
    };
}

public void PlayAudio(string clipName)
{
    // 使用字典获取对应音效
    if (_clipMap.ContainsKey(clipName))
    {
        audioSource.clip = _clipMap[clipName];
        audioSource.Play();
    }
}
```
效果很明显，不再需要编写重复代码，不过缺点也有，使用字典需要额外内存开销，同时需要维护字典，使用字符串作为参数调用，拼写也比较麻烦。

## 使用反射
维护字典比较麻烦，所以考虑使用反射来获取音频变量，然后播放音频。
```csharp
public void PlayAudio(string clipName)
{
    Type type = GetType();
    BindingFlags flag = BindingFlags.Instance | BindingFlags.NonPublic;
    FieldInfo field = type.GetField($"_{clipName}Audio", flag);
    if (field != null)
    {
        audioSource.clip = (AudioClip) field.GetValue(this);
        audioSource.Play();
    }
}
```

这样代码就很精简了，后续增加音频只需要增加变量就行，但同时相对增加了性能开销，代码可读性降低。同时目前的我对unity和c#的一些运行机制还不够了解，有可能会有不可预料的事情发生。。

## 结论
综合上面三种方式，仔细分析利弊，最后还是选择了反射，代码量少，后续增加音频也比较简单。不可控的情况，可以以后再看，遇到了再解决或者对反射有新的认识了再优化。想要技术成长，总是要冒一点风险去探险新的路径。

## 思考
其实本篇博客写的是一件很微不足道的事情，不过自己还是花时间把它记录了下来。一是让自己更加熟悉csharp，例如Dictionary，反射等功能，二是强迫自己写博客，以便以后遇到类似的问题可以快速找回之前的思路，积少成多，自己写代码和博客的能力会越来越强。。
