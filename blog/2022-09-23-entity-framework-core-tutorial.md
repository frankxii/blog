---
slug: entity-framework-core-tutorial
title: 简单使用EF Core框架
authors: frankxii
tags: [Entity, ORM, DB, MySQL]
---

## 引言
最近，在写一款麻将游戏，客户端使用Unity，后端也使用C#来写，前后端统一语言，个人开发比较方便。因为需要存储和读取用户数据，所以需要使用数据库，在自己比较过技术方案以及朋友推荐的情况下，选择了EF框架，下面简单写一下配置和使用过程。


## 安装依赖
使用EF的话，首先需要安装依赖包，.net core环境下，使用NuGet安装第三方库比较方便，所以推荐使用NuGet安装，主要需要安装两个库，`Microsoft.EntityFrameworkCore`和`Pomelo.EntityFrameworkCore.MySql`，前者是EF库，后者是MySQL驱动，其实MySQL驱动除了pomelo外，还有
`MySql.EntityFrameworkCore`，这个库是MySQL官方推出的，按理说使用官方的库更好，但在技术选型过程中发现，微软的EF Core案例中，使用的是pomelo这个库，而且官方驱动居然和dotnet-ef这个工具有些不兼容，遂放弃。  

安装库可以直接在IDE的NuGet中直接安装，也可以使用命令
```shell
dotnet add package Microsoft.EntityFrameworkCore --version 6.0.9
dotnet add package Pomelo.EntityFrameworkCore.MySql --version 6.0.2
```

## 编写Model和Context
安装完依赖之后，便可以开始编写Demo了，需要定义初始化的表和数据库连接类
假设我们要创建一个user表来存放用户数据，按EF案例来定义表(Model)的话，编码如下：
```csharp
public class User
{
    public int UserId { get; set; }
    public string Username { get; set; } = "";
    public int Coin { get; set; }
    public int Diamond { get; set; }
    public byte Gender { get; set; } = 1;
    public DateTime CreateTime { get; set; } = DateTime.Now;
    public DateTime UpdateTime { get; set; } = DateTime.Now;
}
```
编写一个基础的数据类，设定公开属性即可，同时还需要编写访问数据库的Context类
```csharp
public class MahjongDbContext : DbContext
{
    public DbSet<User> User { get; set; } = default!;

    protected override void OnConfiguring(DbContextOptionsBuilder options)
    {
        MySqlServerVersion version = new(new Version(8, 0, 27));
        options.UseMySql("server=localhost;database=Mahjong;user=root;password=123456;", version);
    }
}
```
从代码可以看出，访问类需要继承DbContext类，然后重写事件回调方法，回调方法主要有两个，`OnConfiguring`和`OnModelCreating`，`OnConfiguring`主要用于提供数据库连接字符串，关于数据库配置，可以写在配置文件里，而我的项目本身是练手项目，连接的也是本地数据库，所以就直接填写连接字符串了，而`OnModelCreating`回调，则可以在方法里面使用FluentApi编写表初始化时的一些设置，这里就不再过多展开。



## 迁移与同步
定义完Model和访问类，便可以使用EF的工具自动创建表了，首先需要安装dotnet-ef这个工具，然后添加`Microsoft.EntityFrameworkCore.Design`依赖包，最后执行迁移命令即可，命令如下：
```shell
# 安装dotnet-ef工具
dotnet tool install --global dotnet-ef
# 添加Design依赖包
dotnet add package Microsoft.EntityFrameworkCore.Design
# 生成迁移代码，用于记录数据库版本
dot ef migrations add InitialCreate

```
执行完 migrations命令后，dotnet-ef工具会在项目根目录下生成Migrations文件夹，里面主要包含两类文件，一类是本次迁移对数据库的改动，另一类是数据库快照。
生成迁移文件后，再执行更新命令便可更新Model到数据库，生成数据库表的同时更新字段

```shell
# 更新数据库
dotnet ef database update
```

## 插入与查询数据
创建表和字段后，便可以使用EF来插入、查询数据啦  
简单案例如下：
```csharp
using MahjongDbContext db = new();
User user = new() {Username = "test01", Coin = 3000, Diamond = 500, Gender = 1};
db.User.Add(user);
db.SaveChanges();
```
运行代码后，数据库便新增了一条数据

```csharp
using MahjongDbContext db = new();
User user = db.User.Where(record => record.UserId == 1).First();
user.Coin = 8000;
user.UpdateTime = DateTime.Now;
db.SaveChanges();
```
运行更新代码后，便可以发现Record被更新了  

到此，EF的基础使用便ok了，但仍然还有一些隐藏的问题，比如，自动生成的表名和字段都是按大驼峰，但MySQL推荐命名都是小写+下划线，然后默认的字段类型也不好，例如Username这个字段，可能名称都不会太长，自定义字段类型的话可能使用varchar(16)，但因为设置了Model属性为string类型，EF默认会使用LongText类型，这样就不够精确。

## 优化
更精确地设置表和字段的属性的话，有两种方法，一种是前面提到的在`OnModelCreating`事件回调里使用FluentApi的方式，通过代码调用来设定配置，还有就是通过特性(Attribute)来标注，我个人更喜欢使用注解的方式，这样配置和属性成员可以定义在一起，方便查看。

使用特性后的完善Model代码如下：
```csharp
[Table("user")]
public class User
{
    [Key]
    [Comment("用户ID")]
    [Column("user_id")]
    public int UserId { get; set; }

    [Required]
    [Comment("用户名")]
    [Column("username", TypeName = "varchar(16)")]
    public string Username { get; set; } = "";

    [Required]
    [Comment("金币数量")]
    [Column("coin")]
    public int Coin { get; set; }

    [Required]
    [Comment("钻石数量")]
    [Column("diamond")]
    public int Diamond { get; set; }

    [Range(1, 3)]
    [Comment("姓名，1为男，2为女")]
    [Column("gender", TypeName = "tinyint")]
    public byte Gender { get; set; } = 1;

    [Comment("创建时间")]
    [Column("create_time", TypeName = "timestamp")]
    public DateTime CreateTime { get; set; } = DateTime.Now;

    [Comment("上次更新时间")]
    [Column("update_time", TypeName = "timestamp")]
    public DateTime UpdateTime { get; set; } = DateTime.Now;
}
```
我通过注解，重新定义了表和字段的名称，主键，是否可以为NULL，字段类型，备注等，基本常用的功能都可以使用特性来标注，还是挺不错的。

## 总结
总的来说，EF Core这个ORM框架还是挺不错的，除了前期因为Mac系统运行dotnet环境以及驱动选型踩了一些坑外，其他的流程都还是比较简单且容易理解，后续的ORM操作也挺直观，比手写SQL还是方便了不少。我个人因为之前有接触过Django的ORM，所以对于定义Model，使用迁移命令等都很熟悉，这两个框架不能说大同小异，只能说一模一样了，哈哈。希望在后面的使用中能够对EF Code有更深的理解，后续还可以再更新一些见解。Bye Bye ~ ~

