# 常见 Widgets

## 布局与结构类

- Container：最常用的“万能容器”，可以设置宽高、背景色、边框、圆角、阴影等。
- Row 和 Column：水平方向（Row）和垂直方向（Column）排列子组件，是最常用的线性布局。
- Stack：允许组件像图层一样堆叠在一起（例如在图片上面放一行文字）。
- ListView：可以滚动的列表。如果内容超出了屏幕，必须用它（或者 SingleChildScrollView）来包裹。
- Padding：专门用来给子组件添加内边距。
- SizedBox：用来占据固定尺寸的空白区域，或者强制子组件具有特定的宽高。
- Expanded / Flexible：用在 Row 或 Column 中，用来按比例分配剩余的空间。

## 基础元素类 (Basic UI)

- Text：显示文本。
- Image：显示图片（支持本地 assets、网络图片等）。
- Icon：显示图标（Flutter 内置了丰富的 Material Icons）。

## 交互与按钮类 (Buttons & Interaction)

- ElevatedButton / TextButton / OutlinedButton：不同视觉风格的按钮。
- GestureDetector / InkWell：给任何没有点击事件的组件（比如 Container 或 Image）添加点击、双击、长按、滑动等手势检测。InkWell 还会自带水波纹点击效果。
- TextField：文本输入框。

# 可以继承的 Widget

## StatelessWidget （最常用）

用途：构建无需状态管理的静态 UI
场景：纯展示型组件，如文本、图片、图标等

## StatefulWidget （最常用）

用途：构建需要状态管理（可交互、可变）的 UI
场景：需要响应用户交互、动画、实时更新的组件

## InheritedWidget

用途：在 widget 树中向下传播共享数据
场景：主题（Theme）、语言国际化、状态管理（如 Riverpod/Provider 底层）
示例：Theme.of(context) 就是基于它实现的

## ProxyWidget

用途：代理到另一个 widget
场景：需要在运行时动态替换 child、或者添加中间层

## ParentDataWidget

用途：向父节点传递布局数据
场景：Flex、Stack 等复杂布局的内部实现

## RenderObjectWidget

用途：直接管理渲染对象的底层 widget
场景：需要自定义渲染逻辑时（如自定义绘制）

## LeafRenderObjectWidget

用途：没有子元素的渲染对象
场景：如 Text、Image、Icon 等叶子节点

## SingleChildRenderObjectWidget

用途：只持有单个子组件的渲染对象
场景：如 Padding、Align、Container 等

## MultiChildRenderObjectWidget

用途：持有多个子组件的渲染对象
场景：如 Column、Row、Stack、ListView 等
