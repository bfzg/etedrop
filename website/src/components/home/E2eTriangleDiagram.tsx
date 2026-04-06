import type { ReactNode } from "react";
import useBaseUrl from "@docusaurus/useBaseUrl";
import Translate, { translate } from "@docusaurus/Translate";

export default function E2eTriangleDiagram(): ReactNode {
  // 图片资源
  const cloud = useBaseUrl("/svg/云.svg");
  const chrome = useBaseUrl("/svg/Chrome.svg");
  const windows = useBaseUrl("/img/windows.png");
  const macos = useBaseUrl("/img/macos.png");
  const videoFile = useBaseUrl("/svg/video-file.svg");

  // 核心坐标定义（基于 1000x500 的视口，比例更舒适）
  const topX = 500,
    topY = 120; // 云端（信令）
  const leftX = 180,
    leftY = 380; // 接收端（Chrome）
  const rightX = 820,
    rightY = 380; // 发送端（Win/Mac）
  const leftNodeR = 42;
  const rightNodeHalfW = 60; // 发送端圆角框半宽
  const dataLineX1 = leftX + leftNodeR;
  const dataLineX2 = rightX - rightNodeHalfW;

  return (
    <figure className="relative mt-14 w-full overflow-hidden rounded-3xl border">
      <figcaption className="sr-only">
        <Translate id="homepage.publicE2e.diagram.caption">
          WebRTC 端到端传输示意图：云端负责信令，两端直接进行数据传输
        </Translate>
      </figcaption>

      {/* SVG 画布 */}
      <svg
        viewBox="0 0 1000 500"
        className="w-full h-auto min-h-[280px]"
        role="img"
        aria-hidden
      >
        <defs>
          {/* 节点阴影滤镜 */}
          <filter id="node-shadow" x="-20%" y="-20%" width="140%" height="140%">
            <feDropShadow dx="0" dy="8" stdDeviation="12" floodOpacity="0.08" />
          </filter>
        </defs>

        {/* ================= 背景连线层 ================= */}

        {/* 左侧虚线：云 -> Chrome (信令) */}
        <path
          d={`M ${topX} ${topY} L ${leftX} ${leftY}`}
          stroke="currentColor"
          strokeWidth="2"
          strokeDasharray="6 6"
          className="text-slate-300 dark:text-slate-600"
        />
        {/* 右侧虚线：云 -> 发送端 (信令) */}
        <path
          d={`M ${topX} ${topY} L ${rightX} ${rightY}`}
          stroke="currentColor"
          strokeWidth="2"
          strokeDasharray="6 6"
          className="text-slate-300 dark:text-slate-600"
        />

        {/* 接收端 ↔ 发送端：水平实线 */}
        <line
          x1={dataLineX1}
          y1={leftY}
          x2={dataLineX2}
          y2={rightY}
          stroke="currentColor"
          strokeWidth="3"
          strokeLinecap="round"
          className="text-slate-500 dark:text-slate-400"
        />

        {/* ================= 辅助文字标签层 ================= */}

        {/* 左侧虚线标签 */}
        <g
          className="text-slate-400 dark:text-slate-500"
          transform="translate(290, 240)"
        >
          <rect
            x="-40"
            y="-12"
            width="80"
            height="24"
            rx="12"
            fill="currentColor"
            className="text-white dark:text-slate-900"
          />
        </g>

        {/* 右侧虚线标签 */}
        <g
          className="text-slate-400 dark:text-slate-500"
          transform="translate(710, 240)"
        >
          <rect
            x="-40"
            y="-12"
            width="80"
            height="24"
            rx="12"
            fill="currentColor"
            className="text-white dark:text-slate-900"
          />
        </g>

        {/* 底部实线标签 */}
        <g transform={`translate(${topX}, ${leftY + 20})`}></g>

        {/* ================= 动画层 (文件传输) ================= */}
        <g>
          {/* 让图标沿着实线移动 */}
          <animateMotion
            dur="3.5s"
            repeatCount="indefinite"
            path={`M ${dataLineX2},${rightY} L ${dataLineX1},${leftY}`}
            calcMode="spline"
            keySplines="0.4 0 0.2 1"
          />
          {/* 淡入淡出效果 */}
          <animate
            attributeName="opacity"
            values="0;1;1;0"
            keyTimes="0;0.1;0.9;1"
            dur="3.5s"
            repeatCount="indefinite"
          />
          {/* 文件卡片背景与图标 */}
          <g transform="translate(-30, -30)">
            <image href={videoFile} x="10" y="10" width="40" height="40" />
          </g>
        </g>

        {/* ================= 节点层 ================= */}

        {/* 1. 顶部：云端节点 */}
        <g transform={`translate(${topX}, ${topY})`}>
          <circle
            cx="0"
            cy="0"
            r="48"
            fill="white"
            filter="url(#node-shadow)"
            className="dark:hidden"
          />
          <circle
            cx="0"
            cy="0"
            r="48"
            fill="#0f172a"
            stroke="#334155"
            strokeWidth="2"
            className="hidden dark:block"
          />
          <image href={cloud} x="-28" y="-28" width="56" height="56" />
          <text
            x="0"
            y="70"
            fontSize="14"
            textAnchor="middle"
            className="font-bold fill-slate-700 dark:fill-slate-200"
          >
            {translate({
              id: "homepage.publicE2e.diagram.signaling",
              message: "信令服务",
            })}
          </text>
        </g>

        {/* 2. 左下角：接收端 (Chrome) */}
        <g transform={`translate(${leftX}, ${leftY})`}>
          {/* 主节点 */}
          <circle
            cx="0"
            cy="0"
            r="42"
            fill="white"
            filter="url(#node-shadow)"
            className="dark:hidden"
          />
          <circle
            cx="0"
            cy="0"
            r="42"
            fill="#0f172a"
            stroke="#334155"
            strokeWidth="2"
            className="hidden dark:block"
          />
          <image href={chrome} x="-22" y="-22" width="44" height="44" />
          <text
            x="0"
            y="80"
            fontSize="14"
            textAnchor="middle"
            className="font-bold fill-slate-700 dark:fill-slate-200"
          >
            {translate({
              id: "homepage.publicE2e.diagram.receiver",
              message: "接收端",
            })}
          </text>
          <text
            x="0"
            y="100"
            fontSize="12"
            textAnchor="middle"
            className="fill-slate-500 dark:fill-slate-400"
          >
            {translate({
              id: "homepage.publicE2e.diagram.receiverHint",
              message: "(Web 浏览器)",
            })}
          </text>
        </g>

        {/* 3. 右下角：发送端 (Win/Mac) */}
        <g transform={`translate(${rightX}, ${rightY})`}>
          {/* 圆角矩形背景，用于容纳两个图标 */}
          <rect
            x="-60"
            y="-40"
            width="120"
            height="80"
            rx="24"
            fill="white"
            filter="url(#node-shadow)"
            className="dark:hidden"
          />
          <rect
            x="-60"
            y="-40"
            width="120"
            height="80"
            rx="24"
            fill="#0f172a"
            stroke="#334155"
            strokeWidth="2"
            className="hidden dark:block"
          />

          <image href={windows} x="-40" y="-16" width="32" height="32" />
          {/* 中间分割线 */}
          <line
            x1="0"
            y1="-15"
            x2="0"
            y2="15"
            stroke="currentColor"
            className="text-slate-200 dark:text-slate-700"
            strokeWidth="2"
          />
          <image href={macos} x="8" y="-16" width="32" height="32" />

          <text
            x="0"
            y="70"
            fontSize="14"
            textAnchor="middle"
            className="font-bold fill-slate-700 dark:fill-slate-200"
          >
            {translate({
              id: "homepage.publicE2e.diagram.sender",
              message: "发送端",
            })}
          </text>
          <text
            x="0"
            y="90"
            fontSize="12"
            textAnchor="middle"
            className="fill-slate-500 dark:fill-slate-400"
          >
            {translate({
              id: "homepage.publicE2e.diagram.senderHint",
              message: "(桌面客户端)",
            })}
          </text>
        </g>
      </svg>
    </figure>
  );
}
