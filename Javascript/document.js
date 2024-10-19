var paragraph = document.createElement("p")
var button = document.createElement("button")

document.body.appendChild(paragraph)
paragraph.appendChild(button)

paragraph.textContent = "New Paragraph"

button.addEventListener("click", (newText) => {
    console.log("The " + paragraph.className + " has changed to " + newText)
    paragraph.textContent = newText
})

