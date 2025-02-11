import { marked } from "https://cdn.jsdelivr.net/npm/marked/lib/marked.esm.js";
        // Function to fetch query parameters from the URL
const getQueryParam = (param) => {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get(param);
};

// Main function to render the Markdown file
export const renderMarkdownBlog = async () => {
    const file = getQueryParam('id'); // Get the file name from the query parameter
    const blog_type = getQueryParam('type'); 
    if (!file) {
        document.getElementById('blog-content').innerHTML = '<p>Error: No file specified!</p>';
        return;
    }

    try {
        // Fetch the Markdown file
        const response = await fetch(`/pages/${blog_type}/${file}.md`);
        if (!response.ok) throw new Error(`Unable to fetch file: ${file}`);
        const markdown = await response.text();

        // Convert Markdown to HTML using Marked
        const html = marked(markdown);

        // Insert the converted content into the page
        document.getElementById('blog-content').innerHTML = html;

    } catch (error) {
        console.error('Error rendering blog:', error);
        document.getElementById('blog-content').innerHTML = '<p>Error loading blog content. Please try again later.</p>';
    }
};