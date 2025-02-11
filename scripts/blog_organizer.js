import { blogs } from '/data/blogs.js';
import { populateContent } from '/scripts/populate_list.js';

// TODO: Modify fourth argument to enum
populateContent("blog-list", blogs, "/pages/blog.html", "blogs");
