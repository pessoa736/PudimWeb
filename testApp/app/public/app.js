// PudimWeb Client-side JavaScript

console.log('🍮 PudimWeb app loaded!');

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        document.querySelector(this.getAttribute('href')).scrollIntoView({
            behavior: 'smooth'
        });
    });
});

// Add loaded class for animations
document.addEventListener('DOMContentLoaded', () => {
    document.body.classList.add('loaded');
});
