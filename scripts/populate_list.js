export function populateContent(containerId, blogs, filePath, blog_type) {
    const container = document.getElementById(containerId);
  
    if (!container) {
      console.error(`Container with ID "${containerId}" not found.`);
      return;
    }
  
    let lastYear = null;
  
    blogs.forEach((blog) => {
      // Add year header only when it changes
      if (lastYear !== blog.year) {
        const yearHeader = document.createElement("div");
        yearHeader.classList.add("year-header");
        yearHeader.innerHTML = `<span class="year">${blog.year}</span>`;
        container.appendChild(yearHeader);
        lastYear = blog.year;
      }
  
      // Add month header
      const monthHeader = document.createElement("div");
      monthHeader.classList.add("blog-header");
      monthHeader.innerHTML = `<span class="month">${blog.month}</span>`;
      container.appendChild(monthHeader);
  
      blog.blog_meta_data.sort((a, b) => {
          return b.id - a.id;
      });
      
      // Add each blog item
        blog.blog_meta_data.forEach((meta) => {
        const blogItem = document.createElement("div");
        blogItem.classList.add("blog-item");
        blogItem.innerHTML = `
            <a href="${filePath}?id=${meta.file_name}&type=${blog_type}">
            <span>${meta.title}</span>
            <div class="dots"></div>
            <span class="date">${meta.date}</span>
            </a>
        `;
  
        container.appendChild(blogItem);
      });
    });
  }