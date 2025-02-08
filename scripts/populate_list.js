export function populateContent(containerId, blogs, filePath) {
    const container = document.getElementById(containerId);
  
    if (!container) {
      console.error(`Container with ID "${containerId}" not found.`);
      return;
    }
  
    blogs.forEach((blog) => {
      // Add year and month header
        const header = document.createElement("div");
        header.classList.add("blog-header");
        header.innerHTML = `
        <span class="year">${blog.year}</span>
        <span class="month">${blog.month}</span>
        `;
        container.appendChild(header);
  
      // Add each blog item
        blog.blog_meta_data.forEach((meta) => {
        const blogItem = document.createElement("div");
        blogItem.classList.add("blog-item");
        blogItem.innerHTML = `
            <a href="${filePath}${meta.file_name}.html">
            <span>${meta.title}</span>
            <div class="dots"></div>
            <span class="date">${meta.date}</span>
            </a>
        `;
  
        container.appendChild(blogItem);
      });
    });
  }