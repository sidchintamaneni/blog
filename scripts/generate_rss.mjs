import { readFileSync, writeFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = join(__dirname, "..");

const SITE_URL = "https://sidchintamaneni.com";
const SITE_TITLE = "Siddharth Chintamaneni";
const SITE_DESC = "Blog posts and projects by Siddharth Chintamaneni";

// Load data files by reading as text and evaluating
// (they use ES export syntax but there's no package.json with type:module)
function loadExport(filePath, varName) {
  const src = readFileSync(filePath, "utf-8").replace(/^export\s+/gm, "");
  return new Function(src + `\nreturn ${varName};`)();
}
const blogs = loadExport(join(ROOT, "data", "blogs.js"), "blogs");
const posts = loadExport(join(ROOT, "data", "posts.js"), "posts");

// Month name -> 0-indexed month number
const MONTHS = {
  January: 0, February: 1, March: 2, April: 3,
  May: 4, June: 5, July: 6, August: 7,
  September: 8, October: 9, November: 10, December: 11,
};

// Parse ordinal date string like "11th", "23rd", "1st" -> number
function parseDay(dayStr) {
  return parseInt(dayStr, 10);
}

// Build a Date object from the data structure
function toDate(year, month, dayStr) {
  return new Date(year, MONTHS[month], parseDay(dayStr));
}

// Format a Date as RFC 822 (required by RSS)
function toRFC822(date) {
  return date.toUTCString();
}

// Extract first non-heading, non-empty paragraph from markdown
function extractDescription(mdPath) {
  try {
    const content = readFileSync(mdPath, "utf-8");
    const lines = content.split("\n");
    let paragraph = "";
    for (const line of lines) {
      const trimmed = line.trim();
      // Skip blank lines, headings, blockquotes, horizontal rules
      if (!trimmed || trimmed.startsWith("#") || trimmed.startsWith(">") || trimmed.startsWith("---")) {
        if (paragraph) break; // end of a collected paragraph
        continue;
      }
      // Accumulate paragraph lines
      paragraph += (paragraph ? " " : "") + trimmed;
    }
    // Strip markdown formatting for clean RSS description
    return escapeXml(
      paragraph
        .replace(/\*\[([^\]]+)\]\([^)]+\)\*/g, "$1") // *[text](url)* -> text
        .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")     // [text](url) -> text
        .replace(/\*+([^*]+)\*+/g, "$1")              // **bold** or *italic*
        .replace(/`([^`]+)`/g, "$1")                   // `code`
    );
  } catch {
    return "";
  }
}

function escapeXml(str) {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

// Collect all items from both blogs and posts
const items = [];

function collectItems(groups, type, mdDir) {
  for (const group of groups) {
    for (const meta of group.blog_meta_data) {
      const date = toDate(group.year, group.month, meta.date);
      const link = `${SITE_URL}/pages/blog.html?id=${meta.file_name}&amp;type=${type}`;
      const mdPath = join(ROOT, "pages", mdDir, `${meta.file_name}.md`);
      items.push({
        title: escapeXml(meta.title),
        link,
        pubDate: toRFC822(date),
        date, // for sorting
        categories: meta.tags,
        description: extractDescription(mdPath),
        guid: link,
      });
    }
  }
}

collectItems(blogs, "blogs", "blogs");
collectItems(posts, "posts", "posts");

// Sort newest first
items.sort((a, b) => b.date - a.date);

// Build RSS XML
const itemsXml = items
  .map(
    (item) => `    <item>
      <title>${item.title}</title>
      <link>${item.link}</link>
      <pubDate>${item.pubDate}</pubDate>
${item.categories.map((t) => `      <category>${escapeXml(t)}</category>`).join("\n")}
      <description>${item.description}</description>
      <guid>${item.guid}</guid>
    </item>`
  )
  .join("\n");

const rss = `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
  <channel>
    <title>${SITE_TITLE}</title>
    <link>${SITE_URL}</link>
    <description>${SITE_DESC}</description>
    <atom:link href="${SITE_URL}/feed.xml" rel="self" type="application/rss+xml"/>
${itemsXml}
  </channel>
</rss>
`;

const outputPath = join(ROOT, "feed.xml");
writeFileSync(outputPath, rss, "utf-8");
console.log(`Generated ${outputPath} with ${items.length} items`);
