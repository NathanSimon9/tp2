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
Rammasser toutes les pieces sans perdre ses trois vies pour gagner le niveau. Il est possible de tuer les zombies en sautant sur leur tête pour avoir moin d'obstacle en chemain. Faire perdre les dix vie du géant zombie dans le niveau du boss final pour l'emporter.

## Obstacles à éviter dans les niveaux
### Zombie
### Pique
### Boule tranchante
### Sable mouvent
### Eau

## Pouvoir géant zombie
### 7 vie = apparition de zombie
### 5 vie = Lancement de boule de feux
### 3 vie = Rage

# Arbo


 # niveau 1
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

 # niveau 2
 *node principale*
 ## niveau_2

 *niveau_2 est le parent de tout mes autres node de la scene*
 - **Background** *Node2d pour le decors est placer directement en dessou de "niveau_2"*
 - **TileMapLayer** *Pour le monde*
 - **Scene personnages**
 - **CanvasLayer** *pour mes vie et mon nombre de coins quils reste a l´ecran*
 - **Area2D** *Pour la detection du personnages dans la lave*
 - **canvasLayer2 (parent de Victory label)** Pour le message quand tu passe le niveau*
 - **Node2d nommé danger** *toute mes scenes d'obstacles sont à l'interrieur*
 - **Node2D** *pour les mooving platforms*
 - **Quattre AudioStreamPlayer un à la suite de l'autre** *pour l'ambiance générale*
 - **Area2d nommé pique** *pour detecter lorsqu´il est sur un pique*
 - **Aréa2D nommé boss** *pour détecter quand mon personnage entre dans la porte*
 - **Animation player suivit de colorrect** *pour animation fade in fade out*
 - **Des Scènes coins** *coins dans le jeux*
 - **StaticBody2D** Pour faire mes échelles*
 - **Scène PanneauMessages** *Pour mon affiche*
 - **Scène Node2D2** *mes ressorts*
 - **ScènePauseMenu** *Pour mon menu*
 - **Deux Scène Checkpoint** *Pour Détecter les checkpoints*

# niveau 3
 *node principale*
 ## boss

 *boss est le parent de tout mes autres node de la scene*
 - **Background** *Node2d pour le decors est placer directement en dessou de "boss"*
 - **TileMapLayer** *Pour le monde*
 - **Scene personnages**
 - **CanvasLayer** *pour mes vie et mon nombre de coins quils reste a l´ecran*
 - **Area2D** *Pour la detection du personnages dans la lave*
 - **canvasLayer2 (parent de Victory label)** Pour le message quand tu bat le boss*
 - **Scène enemyboss** *Le boss final avec son code*
 - **Deux AudioStreamPlayer un à la suite de l'autre** *pour l'ambiance générale*
 - **Area2d nommé pique** *pour detecter lorsqu´il est sur un pique*
 - **Animation player suivit de colorrect** *pour animation fade in fade out*
 - **Trois scène Node2D** *mes ressorts*
 - **ScènePauseMenu** *Pour mon menu*

# Autre

*Les autre scène son simple. Elles sont un seul node avec son collision shape et une animation au besoin avec un code attaché au parent*








