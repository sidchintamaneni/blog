document.addEventListener("DOMContentLoaded", () => {
    let pathPrefix = window.location.pathname.includes("/pages/") ? "../" : "./";
    
    fetch(pathPrefix + "pages/footer.html")
        .then(response => response.text())
        .then(data => {
            document.getElementById("footer-placeholder").innerHTML = data;
        })
        .catch(error => console.error("Error loading footer:", error));
});
