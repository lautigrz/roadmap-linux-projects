document.addEventListener("DOMContentLoaded", async function() {
  
    const searchInput = document.getElementById("busqueda");
    const resultsContainer = document.getElementById("results");

    searchInput.addEventListener("keyup", async function(){
        resultsContainer.innerHTML = "";
        const query = searchInput.value.trim();
        if(query.length > 0){
            const charactersQuery = await searchCharacters(query);
            resultsContainer.innerHTML = charactersQuery.map(characters => {
        return buildCharacterCard(characters);
         }).join("");
            
        }else{
             allCharacters(resultsContainer);
        }
    })

    allCharacters(resultsContainer);

});

async function searchCharacters(query) {
    const allCharacters = await searchAllCharacters();
    return allCharacters.filter(character => character.name.toLowerCase().includes(query.toLowerCase()));

}
async function allCharacters(resultsContainer){ 
    const allCharacters = await searchAllCharacters();

    resultsContainer.innerHTML = allCharacters.map(character => {
        return buildCharacterCard(character);
    }).join("");}


function buildCharacterCard(character) {
      const BASE_URL = "https://cdn.thesimpsonsapi.com"
    return `
            <div class="character-card">
                <img class="character-image" src="${BASE_URL}/500${character.portrait_path}" alt="${character.name}">
                <h3 class="name">${character.name}</h3>
                <div class="character-info">
                <p class="age">${character.age ? `Edad: ${character.age}` : ''}</p>
                <p class="${character.status === 'Alive' ? 'alive' : 'dead'}">${character.status}</p>
                </div>
            </div>
        `;


}
async function searchAllCharacters() {
    const url = "https://thesimpsonsapi.com/api/characters"

    try {
        const response = await fetch(url)
        const data = await response.json()

        return data.results
    } catch (error) {
        console.log(error)
    }
}