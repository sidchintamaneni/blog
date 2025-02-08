import { blogs } from '/data/blogs.js';
import { populateContent } from '/scripts/populate_list.js';

// Initialize the blog list
populateContent("blog-list", blogs, "/pages/blogs/");
