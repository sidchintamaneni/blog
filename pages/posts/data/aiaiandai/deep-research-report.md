# Documented timeline of AI predictions and capability milestones since the Transformer era

## Executive summary

This report assembles a documented, source-linked timeline starting with the 2017 Transformer paper and continuing through February 16, 2026 (America/Los_Angeles). It interleaves (A) ambitious public statements—about job displacement, AGI/ASI timelines, and existential/civilizational risk—with (B) contemporaneous papers, model/product releases, and policy/industry events that provide context. The goal is not to be exhaustive, but to create a **rigorous, expandable “spine” timeline** that can be extended in a GitHub repository without inventing any missing specifics. citeturn36view0turn29view0turn5search3

Across the period, several recurring narrative shifts emerge:

From research architecture to scaling and deployment: The Transformer architecture (“Attention Is All You Need,” June 2017) enabled the modern LLM lineage; subsequent milestones like BERT (2018) and GPT-2’s staged/withheld release (2019) show both capability growth and the early emergence of “misuse” narratives. citeturn36view0turn35view0turn34view0

Consumer breakthrough and safety “shock” phase: ChatGPT’s November 2022 release—and GPT-4’s March 2023 release—pushed frontier-model capability into mass public use, coinciding with a rapid rise in “pause/regulation” discourse (open letters, “extinction risk” statements, congressional hearings). citeturn29view0turn31search0turn9search3turn3search0turn3search1

Multimodal and agentic tooling reshapes impact claims: By 2024–2026, the narrative emphasis shifts toward multimodal systems (e.g., GPT-4o, Sora) and “agentic” products (Operator, deep research, ChatGPT agent, Codex app), with a sharper focus on labor-market disruption and social/psychological impacts. citeturn31search1turn2search0turn21search0turn11search0turn21search3turn23search6turn5search3

Present-day endpoint: As of February 13, 2026, OpenAI deprecated GPT-4o and several other models in ChatGPT, while GPT-5 (August 2025) and GPT-5.2 (December 2025) represent a shift toward “unified routing” and “professional/agentic” positioning. citeturn5search0turn5search2turn5search3turn5search1

Key actors and institutions referenced (wrapped once each): entity["company","OpenAI","ai research company"], entity["company","Google","internet technology company"], entity["company","Google DeepMind","alphabet ai lab"], entity["company","Anthropic","ai safety company"], entity["company","Meta","social technology company"], entity["organization","European Union","political union"], entity["country","United States","country"], along with prominent speakers such as entity["known_celebrity","Elon Musk","tesla spacex founder"], entity["people","Sam Altman","openai executive"], entity["people","Dario Amodei","anthropic ceo"], entity["people","Geoffrey Hinton","ai researcher"], entity["people","Demis Hassabis","google deepmind ceo"], and entity["people","Kai-Fu Lee","sinovation ventures founder"]. citeturn34view0turn9search3turn29view0turn5search0turn8search0turn17search5turn17search15turn28view0

## Research approach and definitions

A “documented, sourced timeline” is easiest to maintain if each entry is structured as:

A factual anchor (date + event or statement), supported by a primary source where possible and a reputable secondary source when primary material is unavailable.

A minimal, exact quote for statements; otherwise a faithful summary that explicitly avoids inventing numbers, timelines, or claims not present in the cited source.

A lightweight taxonomy that enables analysis (type, category, tone, topic tags), while keeping the core entry stable for long-term version control. citeturn34view0turn29view0turn5search0turn8search0

Operational definitions used here:

Type = “statement” for a public prediction/claim about AI impacts (jobs, AGI/ASI timelines, existential/civilizational risk), a public call for pause/regulation, or a material risk framing.

Type = “release/event” for a paper release, model/product launch, organizational/policy milestone, or industry event that materially contextualizes statements.

Primary source hierarchy preference: (1) peer-reviewed papers and arXiv preprints; (2) official company blog posts, system cards, and official transcripts; (3) direct interview transcripts/video hosted by the outlet; then (4) reputable news reporting quoting the speaker. This report generally follows that order. citeturn36view0turn35view0turn34view0turn29view0turn9search3turn17search5turn5search1

Tone (for analysis) is coded coarsely as one of: **alarmist/civilizational risk**, **economic disruption/jobs**, **optimistic/abundance**, **skeptical/counter-hype**, or **governance/pause**. This coding is necessarily interpretive and is best treated as an editable field in a repo PR workflow. citeturn3search0turn3search1turn18search0turn6search0turn17search5turn28view0

## Chronological timeline table

Color legend (suggested):
- **Statements**: `#d62728` (red)
- Research/paper release: `#1f77b4` (blue)
- Product/model release: `#2ca02c` (green)
- Policy/regulation milestone: `#9467bd` (purple)
- Industry/corporate event: `#ff7f0e` (orange)

| date | headline | type | full quote or summary | speaker/author and affiliation | primary source URL | color |
|---|---|---|---|---|---|---|
| 2017-06-12 | Transformer architecture introduced (“Attention Is All You Need”) | release/event | Paper introduces the Transformer “based solely on attention mechanisms,” removing recurrence and convolution from the core architecture. citeturn36view0 | entity["people","Ashish Vaswani","transformer paper author"] et al.; Google Research | `https://arxiv.org/abs/1706.03762` citeturn36view0 | #1f77b4 |
| 2017-07 (reported 2017-07-17) | “AI poses ‘existential risk’” in governor briefing | statement | Quoted framing: AI poses “existential risk” / “fundamental risk” and merits proactive regulation (exact phrasing varies by report; prefer the directly quoted lines in the cited coverage). citeturn15search11turn15search10turn32view0 | Elon Musk (Tesla/SpaceX); remarks at National Governors Association meeting (Rhode Island mentioned in coverage). citeturn15search11turn15search10 | `https://www.kqed.org/news/11572736/elon-musk-warns-governors-artificial-intelligence-poses-existential-risk` citeturn15search11 | #d62728 |
| 2018-10-11 | BERT pretraining popularizes bidirectional Transformer encoders | release/event | BERT paper: “Bidirectional Encoder Representations from Transformers,” designed for deep bidirectional pretraining and fine-tuning for downstream NLP tasks. citeturn35view0 | entity["people","Jacob Devlin","bert paper author"] et al.; Google | `https://arxiv.org/abs/1810.04805` citeturn35view0 | #1f77b4 |
| 2018-12-26 | Skeptical AGI timeline framing | statement | “No one can possibly know… there are still probably 10 to 20 breakthroughs needed” and “anyone who tells you and gives you a timeline” is likely overconfident or selling something (short excerpt). citeturn28view0 | Kai-Fu Lee; interview on The Jordan Harbinger Show | `https://www.jordanharbinger.com/kai-fu-lee-what-every-human-being-should-know-about-ai-superpowers/` citeturn28view0 | #d62728 |
| 2019-01-09 | Jobs displacement prediction televised | statement | “AI will displace 40 percent of world’s jobs in as soon as 15 years” (headline claim for the segment; full interview extends beyond the clip). citeturn16search4turn16search7 | Kai-Fu Lee; CBS “60 Minutes” segment | `https://www.cbsnews.com/video/venture-capitalist-kai-fu-lee-ai-will-displace-40-percent-of-worlds-jobs-in-as-soon-as-15-years-60-minutes/` citeturn16search4 | #d62728 |
| 2019-02-14 | GPT-2 introduced; staged release due to misuse concerns | release/event | OpenAI introduces GPT-2; states it is **not releasing the full trained model initially** “due to… concerns about malicious applications.” citeturn34view0 | OpenAI | `https://openai.com/index/better-language-models/` citeturn34view0 | #2ca02c |
| 2019-02-14 | Misuse prediction framing for large language models | statement | The GPT-2 post anticipates misuse such as “Generate misleading news articles,” “Impersonate others online,” and “Automate… spam/phishing content” (examples listed). citeturn34view0 | OpenAI | `https://openai.com/index/better-language-models/` citeturn34view0 | #d62728 |
| 2020-05-28 | GPT-3 paper released | release/event | “Language Models are Few-Shot Learners” introduces GPT-3 (175B parameters) and discusses capability and societal impacts (including difficulty distinguishing generated news from human-written in evaluations). citeturn37view0 | entity["people","Tom B. Brown","gpt-3 paper author"] et al.; OpenAI | `https://arxiv.org/abs/2005.14165` citeturn37view0 | #1f77b4 |
| 2020-06-11 | OpenAI API private beta (commercial deployment pivot) | release/event | OpenAI launches a general “text in, text out” API in private beta and emphasizes controlling harmful uses and learning from real-world deployment. citeturn33view0 | OpenAI | `https://openai.com/index/openai-api/` citeturn33view0 | #2ca02c |
| 2020-06-11 | “We can’t anticipate all consequences” deployment caution | statement | The API post warns it cannot anticipate all consequences, will terminate access for harmful uses, and is launching in private beta partly for safety learning. citeturn33view0 | OpenAI | `https://openai.com/index/openai-api/` citeturn33view0 | #d62728 |
| 2020-11-30 | AlphaFold CASP14 results announced | release/event | DeepMind reports AlphaFold as “a solution to a 50-year-old grand challenge” and describes CASP14 performance, positioning AI as a major scientific accelerator. citeturn13search3 | Google DeepMind | `https://deepmind.google/blog/alphafold-a-solution-to-a-50-year-old-grand-challenge-in-biology/` citeturn13search3 | #2ca02c |
| 2021-03-25 | GPT-3 API ecosystem expansion | release/event | OpenAI reports “Over 300 applications” using GPT-3 via API (early evidence of downstream productization). citeturn19search1 | OpenAI | `https://openai.com/index/gpt-3-apps/` citeturn19search1 | #ff7f0e |
| 2021-06-29 | GitHub Copilot technical preview | release/event | GitHub launches Copilot preview: “your AI pair programmer” (early mass-market code-generation tooling). citeturn22search0 | entity["company","GitHub","code hosting platform"] | `https://github.blog/news-insights/product-news/introducing-github-copilot-ai-pair-programmer/` citeturn22search0 | #2ca02c |
| 2021-08-10 | OpenAI Codex (natural language to code) via API private beta | release/event | OpenAI releases Codex via API private beta; post states it translates natural language to code and references Copilot as a powered product. citeturn27view0 | OpenAI (authors listed on post) | `https://openai.com/index/openai-codex/` citeturn27view0 | #2ca02c |
| 2022-01-28 | Chain-of-thought prompting paper | release/event | Paper finds “chain-of-thought prompting” can improve reasoning performance of sufficiently large LMs (notably on math/logic style tasks). citeturn20search1 | entity["people","Jason Wei","chain-of-thought author"] et al.; Google | `https://arxiv.org/abs/2201.11903` citeturn20search1 | #1f77b4 |
| 2022-03-04 | InstructGPT / RLHF paper | release/event | OpenAI shows instruction-following improvements via RLHF, noting user-preference wins vs a much larger baseline in evaluations. citeturn20search0 | entity["people","Long Ouyang","instructgpt paper author"] et al.; OpenAI | `https://arxiv.org/abs/2203.02155` citeturn20search0 | #1f77b4 |
| 2022-04-06 | DALL·E 2 research launch (text-to-image step change) | release/event | Research launch announcement: DALL·E 2 creates/edits images from natural language; described as a major capability leap in generative media. citeturn12search0 | Sam Altman (OpenAI) | `https://blog.samaltman.com/dall-star-e-2` citeturn12search0 | #2ca02c |
| 2022-06-11 | LaMDA “sentience” claim goes public | statement | A Google engineer claims LaMDA has “come to life” / is sentient (exact transcripts are contested; the claim itself is the salient prediction about AI personhood). citeturn20search6turn20news46turn20news45 | Blake Lemoine (Google; Responsible AI at the time) | `https://www.washingtonpost.com/technology/2022/06/11/google-ai-lamda-blake-lemoine/` citeturn20search6 | #d62728 |
| 2022-08-22 | Stable Diffusion public release | release/event | Stability AI announces public release of Stable Diffusion and DreamStudio Lite; emphasizes “safe and ethical release.” citeturn20search3 | entity["company","Stability AI","generative ai company"] | `https://stability.ai/news/stable-diffusion-public-release` citeturn20search3 | #2ca02c |
| 2022-11-30 | ChatGPT research preview released | release/event | OpenAI launches ChatGPT, describing conversational interaction and RLHF-based training; becomes key inflection point for public adoption. citeturn29view0 | OpenAI | `https://openai.com/index/chatgpt/` citeturn29view0 | #2ca02c |
| 2022-12-15 | Constitutional AI paper | release/event | Anthropic proposes “Constitutional AI: Harmlessness from AI Feedback” (self-critique and rule-based alignment approach). citeturn22search3 | Anthropic research team (paper authors) | `https://arxiv.org/abs/2212.08073` citeturn22search3 | #1f77b4 |
| 2023-02-27 | LLaMA paper released (open-ish weights era) | release/event | LLaMA paper describes foundation models (7B–65B) trained on public datasets; positioned as efficient and competitive. citeturn12search3 | entity["people","Hugo Touvron","llama paper author"] et al.; Meta AI | `https://arxiv.org/abs/2302.13971` citeturn12search3 | #1f77b4 |
| 2023-03 (day varies by publication) | “Pause giant AI experiments” letter | statement | Open letter calls for a **pause** (commonly described as “at least 6 months”) on training frontier systems beyond then-current capability thresholds; details and signatories on source page. citeturn3search0 | entity["organization","Future of Life Institute","ai policy nonprofit"] (open letter) | `https://futureoflife.org/open-letter/pause-giant-ai-experiments/` citeturn3search0 | #d62728 |
| 2023-03-14 | GPT-4 publicly released by OpenAI | release/event | OpenAI describes GPT-4 as “large multimodal,” citing benchmark performance like top-10% simulated bar exam (per their release post). citeturn31search0 | OpenAI | `https://openai.com/index/gpt-4-research/` citeturn31search0 | #2ca02c |
| 2023-03-15 | GPT-4 technical report appears on arXiv | release/event | arXiv submission history shows v1 posted March 15, 2023; report withholds some technical details while describing evaluation and safety approach. citeturn30view0turn18search6 | OpenAI (paper) | `https://arxiv.org/abs/2303.08774` citeturn30view0 | #1f77b4 |
| 2023-03-29 | “Shut it all down” escalation | statement | Essay argues pausing is insufficient and advocates a far more forceful shutdown of frontier training (“We Need to Shut it All Down”). citeturn14search2 | entity["people","Eliezer Yudkowsky","ai theorist"] | `https://time.com/6266923/ai-eliezer-yudkowsky-open-letter-not-enough/` citeturn14search2 | #d62728 |
| 2023-05 (published 2023-05-16) | Senate hearing: “significant harm” downside case | statement | In the Senate hearing transcript, Altman states: “My worst fears are that … [the field] cause significant harm to the world… if this technology goes wrong, it can go quite wrong.” citeturn9search3turn9search11 | Sam Altman; testimony to U.S. Senate Judiciary subcommittee (transcript outlet) | `https://techpolicy.press/transcript-senate-judiciary-subcommittee-hearing-on-oversight-of-ai/` citeturn9search3 | #d62728 |
| 2023-05 (published on site) | “Risk of extinction” consensus statement | statement | Statement: “Mitigating the risk of extinction from AI should be a global priority…” (short excerpt). citeturn3search1 | entity["organization","Center for AI Safety","ai safety nonprofit"] | `https://www.safe.ai/statement-on-ai-risk` citeturn3search1 | #d62728 |
| 2023-10-30 | U.S. executive order on AI | release/event | Executive Order: “Safe, Secure, and Trustworthy Development and Use of Artificial Intelligence.” citeturn3search2 | entity["point_of_interest","The White House","washington, dc, us"] | `https://www.whitehouse.gov/briefing-room/presidential-actions/2023/10/30/executive-order-on-the-safe-secure-and-trustworthy-development-and-use-of-artificial-intelligence/` citeturn3search2 | #9467bd |
| 2023-11 (summit date) | Bletchley Declaration | release/event | UK-hosted AI Safety Summit outputs the “Bletchley Declaration” (baseline international framing around frontier AI risk and cooperation). citeturn3search3 | UK Government / summit participants | `https://www.gov.uk/government/publications/bletchley-declaration-by-countries-attending-the-ai-safety-summit-1-2-november-2023/the-bletchley-declaration-by-countries-attending-the-ai-safety-summit-1-2-november-2023` citeturn3search3 | #9467bd |
| 2023-12-06 | Gemini announced | release/event | Google announces Gemini as a “multimodal” model family (Ultra/Pro/Nano). citeturn13search0 | Google | `https://blog.google/innovation-and-ai/technology/ai/google-gemini-ai/` citeturn13search0 | #2ca02c |
| 2024-02-15 | Gemini 1.5 announced | release/event | Google announces Gemini 1.5, highlighting long-context capabilities and a new MoE architecture (per post). citeturn13search1 | entity["people","Sundar Pichai","alphabet ceo"] and Demis Hassabis; Google | `https://blog.google/innovation-and-ai/products/google-gemini-next-generation-model-february-2024/` citeturn13search1 | #2ca02c |
| 2024-02-15 | Sora introduced | release/event | OpenAI introduces Sora text-to-video (official announcement page). citeturn2search0 | OpenAI | `https://openai.com/index/sora/` citeturn2search0 | #2ca02c |
| 2024-04-18 | Meta Llama 3 released | release/event | Meta releases Llama 3 models (8B and 70B) as “openly available” family, with responsible-use framing. citeturn13search2 | Meta | `https://ai.meta.com/blog/meta-llama-3/` citeturn13search2 | #2ca02c |
| 2024-05-13 | GPT-4o (“Omni”) announced | release/event | OpenAI announces GPT-4o as real-time multimodal (audio/vision/text) flagship model. citeturn31search1 | OpenAI | `https://openai.com/index/hello-gpt-4o/` citeturn31search1 | #2ca02c |
| 2024-05-21 | EU AI Act formally adopted (Council) | release/event | Council of the EU states the AI Act was formally adopted May 21, 2024 and entered into force August 1, 2024. citeturn4search16 | Council of the European Union | `https://www.consilium.europa.eu/en/policies/artificial-intelligence/` citeturn4search16 | #9467bd |
| 2024-09-12 | OpenAI o1-preview (reasoning emphasis) | release/event | OpenAI introduces “o1-preview” models designed to “spend more time thinking before they respond.” citeturn10search0 | OpenAI | `https://openai.com/index/introducing-openai-o1-preview/` citeturn10search0 | #2ca02c |
| 2024-09-23 | “Superintelligence in a few thousand days” | statement | Altman writes: “It is possible that we will have superintelligence in a few thousand days (!); it may take longer, but I’m confident we’ll get there.” citeturn18search0 | Sam Altman | `https://ia.samaltman.com/` citeturn18search0 | #d62728 |
| 2025-01-05 | “We know how to build AGI”; agents join workforce | statement | Altman writes: “We are now confident we know how to build AGI…” and predicts that “in 2025” AI agents may “join the workforce” and materially change output. citeturn18search1 | Sam Altman | `https://blog.samaltman.com/reflections` citeturn18search1 | #d62728 |
| 2025-01-23 | Operator introduced (browser-using agent) | release/event | OpenAI introduces Operator; later updates note integration into ChatGPT agent. citeturn21search0 | OpenAI | `https://openai.com/index/introducing-operator/` citeturn21search0 | #2ca02c |
| 2025-01-23 | Computer-Using Agent (CUA) research release | release/event | OpenAI describes a “universal interface” (Computer-Using Agent) powering Operator. citeturn21search6 | OpenAI | `https://openai.com/index/computer-using-agent/` citeturn21search6 | #1f77b4 |
| 2025-01-23 | Regulatory reversal: EO “removing barriers” | release/event | White House page describes an order “to uphold America’s global AI dominance” and explicitly mentions revoking EO 14110 (Biden-era AI EO). citeturn3search4 | The White House | `https://www.whitehouse.gov/presidential-actions/2025/01/removing-barriers-to-american-leadership-in-artificial-intelligence/` citeturn3search4 | #9467bd |
| 2025-01-31 | o3-mini released | release/event | OpenAI releases o3-mini as cost-efficient reasoning model available in ChatGPT and API. citeturn10search12 | OpenAI | `https://openai.com/index/openai-o3-mini/` citeturn10search12 | #2ca02c |
| 2025-02-02 | Deep research introduced | release/event | OpenAI introduces deep research: multi-step web research producing sourced reports; updates note later integration with agent mode. citeturn11search0turn21search1 | OpenAI | `https://openai.com/index/introducing-deep-research/` citeturn11search0 | #2ca02c |
| 2025-04-14 | GPT-4.1 in the API | release/event | OpenAI launches GPT-4.1 family in API, emphasizing coding/long-context improvements (up to 1M tokens) and refreshed cutoff notes. citeturn10search2 | OpenAI | `https://openai.com/index/gpt-4-1/` citeturn10search2 | #2ca02c |
| 2025-04-16 | o3 and o4-mini released | release/event | OpenAI releases o3 and o4-mini reasoning models; later update notes o3-pro availability. citeturn10search1 | OpenAI | `https://openai.com/index/introducing-o3-and-o4-mini/` citeturn10search1 | #2ca02c |
| 2025-05-28 | White-collar unemployment warning | statement | Axios reports Amodei warning: AI could “wipe out half of all entry-level white-collar jobs” and push unemployment to “10–20%” in “1 to 5 years” (reported summary of interview). citeturn6search0turn6search10 | Dario Amodei; Anthropic (Axios interview) | `https://www.axios.com/2025/05/28/ai-jobs-white-collar-unemployment-anthropic` citeturn6search0 | #d62728 |
| 2025-06-04 | AGI probability framing | statement | Wired quotes Hassabis: “In the next five to 10 years, there’s maybe a 50 percent chance that we’ll have what we define as AGI.” citeturn17search15 | Demis Hassabis; Google DeepMind | `https://www.wired.com/story/google-deepminds-ceo-demis-hassabis-thinks-ai-will-make-humans-less-selfish/` citeturn17search15 | #d62728 |
| 2025-07-17 | ChatGPT agent integrates Operator + deep research | release/event | OpenAI announces ChatGPT agent and notes Operator integration; release notes frame an “agent mode” toolbox. citeturn21search3turn21search0turn21search7 | OpenAI | `https://openai.com/index/introducing-chatgpt-agent/` citeturn21search3 | #2ca02c |
| 2025-08-07 | GPT-5 introduced | release/event | OpenAI introduces GPT-5 as a “unified system” with routing between fast and “thinking” variants. citeturn5search0turn5search1 | OpenAI | `https://openai.com/index/introducing-gpt-5/` citeturn5search0 | #2ca02c |
| 2025-08-27 | Cross-lab evaluation: OpenAI–Anthropic joint safety evaluation | release/event | OpenAI and Anthropic publish findings from a joint safety/misalignment evaluation where each ran internal tests on the other’s released models. citeturn23search7 | OpenAI & Anthropic | `https://openai.com/index/openai-anthropic-safety-evaluation/` citeturn23search7 | #ff7f0e |
| 2025-08-07 to 2025-12-11 | GPT-5.2 introduced (work + agents positioning) | release/event | OpenAI introduces GPT-5.2 emphasizing professional knowledge work and long-running agents; accompanying system card update notes continuity of mitigation approach. citeturn5search2turn5search13 | OpenAI | `https://openai.com/index/introducing-gpt-5-2/` citeturn5search2 | #2ca02c |
| 2025-12-18 | GPT-5.2-Codex introduced | release/event | OpenAI introduces GPT-5.2-Codex as “agentic coding” model; positions it for professional software engineering. citeturn5search6 | OpenAI | `https://openai.com/index/introducing-gpt-5-2-codex/` citeturn5search6 | #2ca02c |
| 2026-01 (essay dated) | “Powerful AI” is near; civilizational “rite of passage” | statement | Amodei’s essay frames a near-term transition: warns of “powerful AI” within “one to two years” (wording varies by section; cite and quote locally when adding excerpts). citeturn8search0turn9search0 | Dario Amodei; Anthropic CEO (personal essay site) | `https://www.darioamodei.com/essay/the-adolescence-of-technology` citeturn8search0 | #d62728 |
| 2026-01-29 (effective 2026-02-13) | Retiring GPT-4o and older ChatGPT models | release/event | OpenAI announces: “On February 13, 2026… we will retire GPT‑4o, GPT‑4.1, GPT‑4.1 mini, and OpenAI o4-mini from ChatGPT.” citeturn5search3turn10search6 | OpenAI | `https://openai.com/index/retiring-gpt-4o-and-older-models/` citeturn5search3 | #2ca02c |
| 2026-02-02 | Codex app for macOS introduced | release/event | OpenAI introduces Codex app as multi-agent workflow “command center” for coding, running tasks in parallel. citeturn23search6turn26news40 | OpenAI | `https://openai.com/index/introducing-the-codex-app/` citeturn23search6 | #2ca02c |
| 2026-02-05 | GPT-5.3-Codex introduced | release/event | OpenAI introduces GPT‑5.3‑Codex as more capable agentic coding model, combining GPT-5.2-Codex frontier coding with GPT-5.2 reasoning/knowledge. citeturn22search9turn23search9 | OpenAI | `https://openai.com/index/introducing-gpt-5-3-codex/` citeturn22search9 | #2ca02c |
| 2026-02-13 | GPT-4o deprecation in ChatGPT completes | release/event | Help Center notes: GPT-4o “deprecated in ChatGPT on February 13, 2026” (API availability unchanged per notice). citeturn5search7 | OpenAI Help Center | `https://help.openai.com/en/articles/20001051-retiring-gpt-4o-and-other-chatgpt-models` citeturn5search7 | #ff7f0e |

## Tone and frequency analysis

The counts below are computed **only from the “statement” rows included in the table above** (a curated sample, not a census of all AI predictions). This design is intentional: making the dataset explicit and auditable is more valuable than claiming completeness. citeturn34view0turn28view0turn18search0turn18search1turn17search5turn6search0turn8search0turn3search0turn3search1turn14search2turn9search3

### Frequency and tone by year

| year | prediction statements in this timeline | alarmist/civilizational risk | economic disruption/jobs | optimistic/abundance | skeptical/counter-hype | governance/pause |
|---|---:|---:|---:|---:|---:|---:|
| 2017 | 1 | 1 | 0 | 0 | 0 | 0 |
| 2018 | 1 | 0 | 0 | 0 | 1 | 0 |
| 2019 | 2 | 0 | 1 | 0 | 0 | 1 |
| 2020 | 1 | 0 | 0 | 0 | 0 | 1 |
| 2021 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2022 | 1 | 0 | 0 | 0 | 0 | 1 |
| 2023 | 4 | 2 | 0 | 0 | 0 | 2 |
| 2024 | 1 | 0 | 0 | 1 | 0 | 0 |
| 2025 | 4 | 1 | 1 | 0 | 0 | 2 |
| 2026 | 1 | 1 | 0 | 0 | 0 | 0 |

Interpretive reading (and why it matters for a maintainable repo):

The “governance/pause” and “alarmist/civilizational risk” tones cluster in 2023, aligning temporally with GPT-4’s release and a broader sense that frontier capability was entering a new regime. citeturn31search0turn3search0turn3search1turn14search2turn9search3

The “optimistic/abundance” tone becomes more explicit again in 2024 with “superintelligence in a few thousand days,” even as policy hardens (EU AI Act adoption and entry into force). citeturn18search0turn4search16

The 2025–2026 period mixes (i) “workforce/agent” predictions and (ii) increased productization of agents (Operator, deep research, ChatGPT agent, Codex), suggesting a feedback loop: product releases make “agents replacing workers” claims more imaginable and therefore more frequent. citeturn18search1turn21search0turn11search0turn21search3turn6search0turn23search6

## Mermaid visualization of narrative tone shifts

```mermaid
flowchart LR
  A[Transformer era: architecture optimism\n(2017–2018)] --> B[Scaling + cautious disclosure\n(GPT-2 / API era)]
  B --> C[Capability jumps + broad adoption\n(ChatGPT)]
  C --> D[Governance shock + existential framing\n(pause letters, extinction statements,\ncongressional testimony)]
  D --> E[Multimodal race + open model ecosystems\n(Gemini, Llama, GPT-4o, Sora)]
  E --> F[Agentic automation: web + research + coding\n(Operator, deep research, ChatGPT agent, Codex)]
  F --> G[Societal impacts foregrounded\n(jobs, inequality, human attachment,\nmodel access decisions)]
```

Interpretation guidance: this diagram is intentionally coarse; a repo should include a per-entry `tone` and then generate an updated diagram automatically (e.g., via scripts or a docs build step) once the dataset grows. citeturn36view0turn34view0turn29view0turn31search0turn3search0turn3search1turn21search0turn11search0turn21search3turn5search3

## GitHub-friendly schema for timeline entries

A practical schema should (1) preserve the required fields exactly as requested, (2) allow metadata expansion without breaking old entries, and (3) support JSON/YAML diffs.

### Suggested JSON Schema

```json
{
  "id": "string (stable slug, e.g., 2022-11-30-openai-chatgpt)",
  "date": "string (ISO-8601 preferred; allow 'YYYY-MM' when day unknown)",
  "headline": "string",
  "type": "statement | release/event",
  "quote_or_summary": "string",
  "speaker_or_author": {
    "name": "string",
    "affiliation": "string",
    "role": "string (optional)"
  },
  "primary_source_url": "string",
  "secondary_sources": ["string (optional)", "string (optional)"],
  "color": "string (hex)",
  "tags": ["string (optional)"],
  "tone": "alarmist | jobs | optimistic | skeptical | governance (optional)",
  "notes_uncertainty": "string (optional; required when date/quote is partial)"
}
```

### Parallel YAML example

```yaml
- id: 2024-09-23-altman-intelligence-age-superintelligence
  date: "2024-09-23"
  headline: "Superintelligence in a few thousand days"
  type: "statement"
  quote_or_summary: "“It is possible that we will have superintelligence in a few thousand days (!); it may take longer, but I’m confident we’ll get there.”"
  speaker_or_author:
    name: "Sam Altman"
    affiliation: "OpenAI (exec; personal blog post)"
  primary_source_url: "https://ia.samaltman.com/"
  secondary_sources: []
  color: "#d62728"
  tags: ["asi", "timeline", "optimism"]
  tone: "optimistic"
  notes_uncertainty: ""
```

This schema directly supports the timeline table fields, while adding optional analytic fields (`tone`, `tags`, `notes_uncertainty`) needed to generate repeatable charts/diagrams. citeturn18search0turn5search0turn5search2turn21search3

## Uncertainties and limitations

Event-date ambiguity in reporting: Some high-profile statements (e.g., ad-lib remarks at live events) are often quoted via reporting published days later. Where the exact utterance date is not clearly stated in the primary/nearest source, the timeline should store either (a) the source publication date or (b) a month-level date and mark `notes_uncertainty`. This is especially relevant for widely repeated phrases like “existential risk” comments in governor meetings, where multiple outlets paraphrase. citeturn15search11turn15search10turn32view0

Quote fidelity vs. paraphrase: Some entries (notably “open letter” summaries or interview writeups) contain author summaries rather than verbatim quotations. The timeline should explicitly label such text as “reported summary” and—in a fuller build—add a second field for “verbatim quote” only when a transcript/video segment is available. citeturn6search0turn3search0turn9search3turn17search15

Definition drift (“AGI,” “superintelligence,” “agents”): Multiple sources use the same term with different implied thresholds (capability, autonomy, economic impact). A robust repo should add a `definition_context` note (e.g., “AGI defined as X by speaker”) when present; when absent, it should avoid asserting a definition. citeturn18search1turn18search0turn17search15turn21search3turn5search1

Selection bias: This report’s table is a seed dataset emphasizing widely cited milestones and prominent speakers. It omits many important developments (e.g., sector-specific deployments, safety research subfields, non-frontier models) that may be crucial depending on the intended narrative. Treat the current output as a structured starting point to expand, not an authoritative complete history. citeturn11search0turn13search2turn20search0turn22search3turn10search1