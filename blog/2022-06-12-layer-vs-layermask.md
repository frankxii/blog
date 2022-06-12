---
slug: layer-vs-layermask
title: Unity 踩坑LayerMask
authors: frankxii
tags: [Unity, LayerMask, Layer]
---

## 起因
跟完mike的SunnyLand教程后，开始重写游戏，以加深印象和理解，在多处动画状态转化中，都需要判断是否接触地面，mike的做法是声明一个public `LayerMask` 变量，然后在编辑器中选取对应的Ground `Layer`，而我在重写过程中，不想在编辑器绑定，而是通过代码实现，代码如下:

```csharp
//是否接触地面
private bool IsTouchingGround()
{
    LayerMask ground = LayerMask.NameToLayer("Ground");
    return Physics2D.OverlapCircle(_foot.position, 0.2f, ground);
}
```
结果返回值始终为`false`，我百思不得其解，之前使用了`Overlap`检测是ok的，ground layer的拼写也没错，怎么就检测不到呢。

## 排查问题
打印一下ground的值
```csharp
Debug.Log($"Ground {ground.value}");
```
结果为8，也没错呀，和ground layer的序号一致。于是便陷入了误区，出现以下猜测：

1. OverlapCircle的半径值不对，导致没检测到。
2. 角色胶囊collider没设置对，导致_foot物体没接触到地面。
3. _foot子物体绑定出错或者在start获取的时候出错。

尝试排查以上问题，均无效😓

没办法，只能走老路子，声明Ground `LayerMask`，绑定`Layer`，再来试试，成功了🤔
```csharp
public LayerMask Ground;

private bool IsTouchingGround()
{
    return Physics2D.OverlapCircle(_foot.position, 0.2f, Ground);
}
```

既然通过编辑器绑定layer可以，而我自己写的代码不行，那一定是ground这个变量有问题！

打印一下
```csharp
Debug.Log($"Ground1 {ground.value}");
Debug.Log($"Ground2 {Ground.value}");
```

## 问题根源
Ground1的值为8，Ground2的值为256，果然不一样，但为什么Ground的值是256呀，layer序号为8呀，总共也只有32个layer呀。。不甘心😡，查google，查官方文档，终于找到了大致的说法。

`A layer is a standard integer, but a layerMask is an integer formatted as a bitmask where every 1 represents a layer to include and every 0 represents a layer to exclude.`

Layer用`十进制`表示，如layer ground的`索引`是8，而LayerMask则是`二进制`按位表示，`Layer`转成`LayerMask`之后则是000100000000，`LayerMask.NameToLayer()`方法返回值并不是`LayerMask`而是Layer的索引值。自己先入为主了，以为LayerMask类的方法会返回LayerMask，而且不清楚Layer和LayerMask的区别，导致以为返回值是对的。

## 解决问题
既然找到了问题点，便尝试开始解决，把Layer的索引值转为LayerMask，也就是官网说的`bitmask`，可用`位操作`。
```csharp
private bool IsTouchingGround()
{
    LayerMask ground = 1 << LayerMask.NameToLayer("Ground");
    return Physics2D.OverlapCircle(_foot.position, 0.2f, ground);
}
```

搞定，把1移位layer的索引次，可以获得对应的bitmask。
但是用位操作，代码可读性太差了吧，有没有更好的解决办法🤔?

有的，使用LayerMask.GetMask，来看看`GetMask`的方法签名和具体实现
```csharp
public static int GetMask(params string[] layerNames)
{
  if (layerNames == null)
    throw new ArgumentNullException(nameof (layerNames));
  int mask = 0;
  foreach (string layerName in layerNames)
  {
    int layer = LayerMask.NameToLayer(layerName);
    if (layer != -1)
      mask |= 1 << layer;
  }
  return mask;
}
```
通过传入layer name字符串参数数组，返回所有layer的bitmask并集，而我因为对LayerMask和csharp的`params`关键字不熟悉，先入为主的以为要传入一个字符串数组，最后接收mask数组😅，太麻烦了所以没有用，而使用了`NameToLayer`😂，`GetMask`其实很简单。

```csharp
LayerMask ground = LayerMask.GetMask("Ground");
LayerMask ground = LayerMask.GetMask("Ground", "Default");
```
是的，想象中的字符串数组结果可以直接传字符串，而且可以传多个字符串😂，因为params关键字声明的是一个可变多参数，和Python的*args异曲同工。

## 总结
为什么一个看似简单的问题，可以出现这么多错误，浪费了很多时间才解决。最主要的原因是先入为主，以自己以往对事物的认识形成的刻板印象来认识新的事物，实际结果可能是千差万别。如果对LayerMask和csharp多参数有足够的认识，可以快速解决问题。

## 思考
先入为主更深层次的原因在于对unity原理和csharp语法不熟悉，不是我不想了解和学习这些知识，只是先学习各种理论的话进度很慢。

这涉及到两种学习方式，一是先花时间学习系统的理论，二是直接实践上手，在做中学。更加升华的话则是`理论`和`实践`的关系。。最好的方法是`两者结合，以理论指导实践，以实践理解和完善理论`。

自己有时间的话还需要加强对unity原理和csharp编程的理解。