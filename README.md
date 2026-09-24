# 知源 · 资源分享平台

一个可部署到 GitHub Pages 的静态资源分享网站原型。页面参考了资源平台常见的信息架构，但使用独立品牌、示例内容和实现。

## 本地运行

```bash
npm install
npm run dev
```

生产构建：

```bash
npm run build
npm run preview
```

## Supabase 初始化

1. 在 Supabase SQL Editor 中执行 `supabase/schema.sql`。
2. 在 GitHub 仓库 Actions Secrets 中设置 `VITE_SUPABASE_URL` 和 `VITE_SUPABASE_PUBLISHABLE_KEY`。
3. 前端会优先读取 Supabase 中 `status = published` 的资源；连接失败时保留演示数据。
4. `VITE_SUPABASE_URL` 应填写项目根地址（例如 `https://your-project.supabase.co`），不要带 `/rest/v1/`。

## GitHub Pages 部署

仓库 Settings → Pages → Source 选择 **GitHub Actions**。项目已经提供 `.github/workflows/deploy.yml`，推送到 `main` 后会自动构建并发布。

## 当前能力

- 首页仪表盘、统计卡片、最近更新资源
- 资源搜索、分类筛选、排序和分页
- 资源详情抽屉、下载按钮
- 基于浏览器 localStorage 的收藏
- 响应式布局，可在手机端访问

## 后端边界

GitHub Pages 只能托管静态文件，不能安全地提供账号、文件上传、数据库和权限管理。当前的登录、上传、后台管理入口展示为规划状态。若要启用这些能力，需要另配后端服务（例如 Supabase、Cloudflare Workers 或自建 API），并把 `src/main.js` 中的静态数据层替换为 API 调用。
