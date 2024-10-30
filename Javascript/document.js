var paragraph = document.createElement("p") // Paragraph
var button = document.createElement("button")

document.body.innerHTML.appendChild(paragraph)
paragraph.appendChild(button)

paragraph.textContent = "New Paragraph"
button.textContent = "Click Me!"
button.onclick = function () {
    paragraph.textContent = "I was clicked!"
}
button.onclick = function (content) {
    paragraph.content = content
}
