import { posts } from '/data/posts.js';
import { populateContent } from '/scripts/populate_list.js';

// TODO: Modify fourth argument to enum
populateContent("post-list", posts, "/pages/blog.html", "posts");
