# Jeux style pixel

## Un chevalier est dans une quête pour allez dans le chateau et sauver sa bien aimer des mains du géant zombie. Le parcours ne sera pas facile car plusieur des guerriers zombie protège le chateau. Saura tu aider notre chevalier a sauver la princesse ?


## Touches
### "D" pour Avancer
### "A" pour Reculer
### "W" pour Sauter
### "S" pour Se baisser et glisser
### "Backspace" pour Le menu pause
### Les flèches fonctionne aussi pour les mouvements

## But
Rammasser toutes les pieces sans perdre ses trois vies pour gagner le niveau. Il est possible de tuer les zombies en sautant sur leur tête pour avoir moin d'obstacle en chemain.

## Obstacles à éviter
### Zombie
### Boule tranchante
### Sable mouvent
### Eau

# Arbo

 *node principale*
 ## jeu

*jeux est le parent de tout mes autres node de la scene principale*
 - **Plusieurs Sprite** *pour le decors sont placer en dessou directement en dessou de "jeu"*
 - **Scène Personnage** *pour mon personnage avec son script*
 - **Deux camera limit** *pour avoir une limite sur ma camera*
 - **CanvasLayer** *pour mes vie et mon nombre de coins quils reste a l´ecran*
 - **Node 2d nommer danger** *mes scenes ennemies son placer dans ce groupe avec leur script*
 - **plusieurs sprites nuages** *pour quils soit devant le perso*
 - **Node2d coins** *Tout mes scenes coins avec leur script a l´interrieur*
 - **Scenee Area2d avec script dans le groupe affiche** *pour zoom sur les affiche*
 - **deux characterbody2d** *pour les mooving platforms*
 - **2Area 2d** *pour detecter lorsqu´il est dans l´eau ou dans le sable*
 - **Audiostreamplayer** *pour la musique de fond*
 - **2 Autres scene affiche**
 - **Scène PauseMenu**
 - **StaticBody2D** *pour mettre des mures invisible*
 - **canvasLayer** *pour les label de victoir et defaite*








