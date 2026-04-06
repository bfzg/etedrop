import type { ReactNode } from "react";
import { useId, useState } from "react";
import clsx from "clsx";
import Heading from "@theme/Heading";
import Translate from "@docusaurus/Translate";
import Container from "../Container";

function ChevronIcon({ className }: { className?: string }): ReactNode {
  return (
    <svg
      className={className}
      viewBox="0 0 20 20"
      fill="currentColor"
      aria-hidden
    >
      <path
        fillRule="evenodd"
        d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
        clipRule="evenodd"
      />
    </svg>
  );
}

type FaqItemProps = {
  panelId: string;
  buttonId: string;
  isOpen: boolean;
  onToggle: () => void;
  q: ReactNode;
  a: ReactNode;
};

function FaqItem({
  isOpen,
  panelId,
  buttonId,
  onToggle,
  q,
  a,
}: FaqItemProps): ReactNode {
  return (
    <li className="w-full flex flex-col">
      <Heading as="h3" className="m-0 w-full">
        <button
          id={buttonId}
          type="button"
          className={clsx(
            "flex w-full items-center justify-between rounded-2xl px-6 py-5 text-left text-[1.1rem] font-semibold transition-all duration-300 outline-none",
            isOpen
              ? "bg-white border-2 border-black shadow-[4px_4px_0_0_#000] text-black "
              : "border-none bg-slate-100/80  text-slate-800 hover:bg-slate-200/80 ",
          )}
          aria-expanded={isOpen}
          aria-controls={panelId}
          onClick={onToggle}
        >
          <span className="min-w-0 flex-1">{q}</span>
          <ChevronIcon
            className={clsx(
              "h-6 w-6 shrink-0 transition-transform duration-300",
              isOpen
                ? "rotate-180 text-black dark:text-white"
                : "text-slate-500 dark:text-slate-400",
            )}
          />
        </button>
      </Heading>

      <div
        id={panelId}
        role="region"
        aria-labelledby={buttonId}
        className={clsx(
          "grid w-full transition-all duration-300 ease-in-out",
          isOpen
            ? "grid-rows-[1fr] opacity-100 mt-3"
            : "grid-rows-[0fr] opacity-0 mt-0",
        )}
      >
        <div className="min-h-0 overflow-hidden">
          <p className="m-0 px-6 pb-2 pt-1 text-lg leading-relaxed text-slate-700 dark:text-slate-400">
            {a}
          </p>
        </div>
      </div>
    </li>
  );
}

export default function HomeFaq(): ReactNode {
  const baseId = useId();
  const [openId, setOpenId] = useState<string | null>("faq-1");

  return (
    <section className="w-full py-16">
      <Container>
        <div className="mb-10 text-center">
          <Heading
            as="h2"
            className="text-4xl font-bold tracking-wide text-slate-900 dark:text-white"
          >
            <Translate id="homepage.faq.title">常见问题</Translate>
          </Heading>
        </div>

        <ul className="mx-auto flex w-full max-w-4xl flex-col gap-5 p-0 list-none">
          <FaqItem
            panelId={`${baseId}-faq-1-panel`}
            buttonId={`${baseId}-faq-1-btn`}
            isOpen={openId === "faq-1"}
            onToggle={() =>
              setOpenId((prev) => (prev === "faq-1" ? null : "faq-1"))
            }
            q={
              <Translate id="homepage.faq.1.q">是否依赖中心化存储？</Translate>
            }
            a={
              <Translate id="homepage.faq.1.a">
                核心传输尽量走端到端直连；服务端主要负责在线管理与信令转发。
              </Translate>
            }
          />
          <FaqItem
            panelId={`${baseId}-faq-2-panel`}
            buttonId={`${baseId}-faq-2-btn`}
            isOpen={openId === "faq-2"}
            onToggle={() =>
              setOpenId((prev) => (prev === "faq-2" ? null : "faq-2"))
            }
            q={<Translate id="homepage.faq.2.q">公网环境能用吗？</Translate>}
            a={
              <Translate id="homepage.faq.2.a">
                支持的，80% 的用户网络环境支持 p2p 传输。如不支持请截图联系我们。
              </Translate>
            }
          />
          <FaqItem
            panelId={`${baseId}-faq-3-panel`}
            buttonId={`${baseId}-faq-3-btn`}
            isOpen={openId === "faq-3"}
            onToggle={() =>
              setOpenId((prev) => (prev === "faq-3" ? null : "faq-3"))
            }
            q={
              <Translate id="homepage.faq.3.q">支持哪些文件类型在线预览？</Translate>
            }
            a={
              <Translate id="homepage.faq.3.a">
                目前仅支持 Mp4 视频在线预览。其他格式如图片、文档、音频等，后续会支持。
              </Translate>
            }
          />
          <FaqItem
            panelId={`${baseId}-faq-4-panel`}
            buttonId={`${baseId}-faq-4-btn`}
            isOpen={openId === "faq-4"}
            onToggle={() =>
              setOpenId((prev) => (prev === "faq-4" ? null : "faq-4"))
            }
            q={<Translate id="homepage.faq.4.q">如何反馈问题？</Translate>}
            a={
              <Translate id="homepage.faq.4.a">
                请截图，并描述问题，发送邮件至 yuanzhou_cn@qq.com
              </Translate>
            }
          />
        </ul>
      </Container>
    </section>
  );
}
