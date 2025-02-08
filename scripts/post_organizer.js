import { posts } from '/data/posts.js';
import { populateContent } from '/scripts/populate_list.js';

// Initialize the blog list
populateContent("post-list", posts, "/pages/posts/");
