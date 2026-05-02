# Rin Blog Client


<p align="center">
  一个基于 Flutter 的 Rin 博客安卓客户端
</p>

<p align="center">
  <a href="https://github.com/openRin/Rin">原项目 Rin</a> ·
</p>

---

## 项目简介

Rin Blog Client 是基于开源博客平台 [Rin](https://github.com/openRin/Rin) 构建的安卓客户端应用，采用 Flutter 框架开发，支持 Material 3 设计规范和 Riverpod 状态管理。

Rin 是一个现代化的无服务器博客平台，完全构建在 Cloudflare 开发平台上：使用 Pages 托管静态资源、Workers 提供无服务器函数、D1 提供 SQLite 数据库、R2 提供对象存储。只需配置一个域名指向 Cloudflare，即可部署个人博客，无需管理服务器。

本项目为 Rin 博客平台提供了移动端访问能力，让您可以随时随地管理博客内容、浏览友链动态。

## 功能特性

### 核心功能

- **文章管理**：浏览、创建、编辑、删除文章，支持 Markdown 渲染
- **动态中心**：查看和管理博客动态
- **友链管理**：浏览和管理博客好友链接
- **用户认证**：GitHub OAuth 登录认证
- **隐私控制**：支持仅自己可见的文章

### 技术特性

- **BaseURL 动态配置**：支持在设置页修改 API 地址，运行时切换无需重新安装
- **Token 自动管理**：自动在请求头注入认证 Token
- **登录失效处理**：401 响应自动跳转登录页
- **Markdown 渲染**：文章详情全屏渲染，编辑页支持编辑/预览切换
- **流畅体验**：下拉刷新、分页加载、加载动画、空状态提示、删除确认

### 界面特性

- **Material 3 设计**：遵循最新 Material Design 3 规范
- **底部导航可定制**：动态、友链、关于页面可在设置中开关显示
- **深色模式支持**：支持夜间模式

## 软件截图

### 文章列表页面

![文章列表](https://pic1.imgdb.cn/item/69f6255abd91a69b7b942d5a.png)

### 友链页面

![友链页面](https://pic1.imgdb.cn/item/69f6257dbd91a69b7b942e04.png)

### 文章详情页面

![文章页面](https://pic1.imgdb.cn/item/69f6259abd91a69b7b942e9d.png)

### 设置页面

![设置页面](https://pic1.imgdb.cn/item/69f625b2bd91a69b7b942f20.png)

## 安装说明

### 系统要求

- Android 5.0 (API 21) 或更高版本
- 支持armeabi-v7a、arm64-v8a、x86_64架构


## 使用指南

### 首次配置

1. 首次启动应用后，进入 **设置** 页面
2. 修改 **BaseURL** 为你的 Rin 博客地址（如 `https://your-blog.com/`）
3. 点击保存



### 友链管理

- 查看所有已添加的博客好友链接
- 点击链接可在应用内打开或跳转至浏览器

### 设置

- **BaseURL 配置**：修改 API 服务器地址
- **深色模式**：切换应用主题
- **底部导航定制**：选择显示或隐藏动态、友链、关于页面

## 项目结构

```
lib/
├── app/
│   └── app.dart              # 应用入口（MaterialApp/路由/主题）
├── pages/
│   ├── login_page.dart      # 登录页面
│   ├── splash_page.dart     # 启动页面
│   ├── shell_page.dart      # 底部导航容器
│   ├── feed_list_page.dart  # 文章列表页
│   ├── feed_detail_page.dart # 文章详情页
│   ├── feed_editor_page.dart # 文章编辑页
│   ├── moments_page.dart    # 动态页面
│   ├── moments_detail_page.dart # 动态详情页
│   ├── friend_page.dart     # 友链页面
│   ├── about_page.dart      # 关于页面
│   └── settings_page.dart   # 设置页面
├── models/
│   ├── feed_item.dart       # 文章数据模型
│   ├── moment.dart          # 动态数据模型
│   ├── friend_link.dart     # 友链数据模型
│   └── comment.dart         # 评论数据模型
├── services/
│   ├── api_client.dart      # Dio HTTP 客户端封装
│   └── local_storage.dart   # 本地存储服务
├── providers/
│   ├── auth_provider.dart   # 认证状态管理
│   ├── feed_provider.dart   # 文章状态管理
│   ├── moments_provider.dart # 动态状态管理
│   └── settings_provider.dart # 设置状态管理
├── utils/
│   ├── app_router.dart      # 路由配置
│   └── ui.dart              # UI 工具类
└── main.dart                # 应用入口文件
```

## API 接口

本客户端严格按 Rin 后端接口实现：

| 模块 | 接口 |
|------|------|
| 认证 | `POST /api/auth/login`, `GET /api/auth/status` |
| 文章 | `GET /api/feed`, `GET /api/feed/timeline`, `GET /api/feed/:id`, `POST /api/feed`, `PUT /api/feed/:id`, `DELETE /api/feed/:id` |
| 动态 | `GET /api/moments`, `POST /api/moments`, `POST /api/moments/:id`, `DELETE /api/moments/:id` |
| 友链 | `GET /api/friend`, `POST /api/friend`, `PUT /api/friend/:id`, `DELETE /api/friend/:id` |
| 用户 | `POST /api/user/logout` |

## 技术栈

- **Flutter** - 跨平台 UI 框架
- **Dart** - 编程语言
- **Riverpod** - 状态管理
- **Dio** - HTTP 客户端
- **flutter_markdown** - Markdown 渲染
- **shared_preferences** - 本地存储
- **Material 3** - 设计规范

## 开发相关

### 环境要求

- Flutter SDK 3.11+
- Dart SDK 3.11+
- Android Studio / VS Code with Flutter 插件

### 运行开发版本

```bash
flutter pub get
flutter run
```

### 构建发布版本

```bash
flutter build apk --release
```

## 相关链接

- **Rin 原项目**: https://github.com/openRin/Rin
- **Rin 官方文档**: https://docs.openrin.org
- **在线演示**: https://xeu.life
- **问题反馈**: https://github.com/openRin/Rin/issues
