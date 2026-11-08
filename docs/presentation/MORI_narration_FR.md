# MORI — Texte de présentation en français

Objectif : environ 4 minutes, manipulations à l’écran comprises. Répétez avec un chronomètre et gardez la vidéo finale sous 5 minutes. Lisez uniquement le texte de présentation, pas les indications à l’écran. Utilisez des symptômes fictifs et présentez l’application en français. Si la reconnaissance vocale ne fonctionne pas, saisissez la même phrase au clavier et continuez.

## 1. Le problème — face caméra, puis écran d’accueil MORI

Bonjour, je m’appelle Caroline. Je suis une étudiante française en échange en Corée.

Ce projet est né d’une difficulté que j’ai moi-même rencontrée. Quand je me sentais malade en Corée, je me posais deux questions : dans quelle clinique aller ? Et comment expliquer mes symptômes en coréen ?

Il existe de nombreuses spécialités médicales. Quand on ne connaît pas le système de santé, choisir un établissement peut être déroutant. Et trouver une clinique ne résout pas la barrière de la langue une fois sur place.

Mon coéquipier s’occupe du développement, et j’apporte l’expérience de l’étudiante pour laquelle nous concevons cette application.

Ensemble, nous avons créé MORI : trouver une clinique et expliquer ses symptômes en coréen.

## 2. Trouver des soins — urgence / clinique → oreilles, nez et gorge → clinique Yangdeok

Pour ce prototype, nous nous concentrons sur les étudiants internationaux de l’université Handong qui préparent une consultation non urgente à Pohang.

Le premier écran distingue l’aide en cas d’urgence de la recherche d’une clinique. Les informations d’urgence sont accessibles sans compte.

Pour une consultation non urgente, je peux explorer les spécialités à l’aide d’images et de libellés. Ici, je choisis « oreilles, nez et gorge ».

L’annuaire utilise un jeu de données daté provenant de HIRA, l’organisme coréen d’évaluation des soins et de l’assurance maladie. Il ne présente pas les horaires en temps réel. Je dois donc les vérifier auprès de la clinique avant de m’y rendre.

Je sélectionne une clinique et j’appuie sur « Préparer cette visite ». Je peux continuer en tant qu’invitée.

## 3. Préparer ce que je vais dire — saisie d’un exemple fictif en français

Je vais maintenant faire une démonstration avec un exemple fictif.

J’écris en français : « J’ai mal à la gorge depuis deux jours. »

MORI me demande quel symptôme me gêne le plus, quand il a commencé, ainsi que mes allergies et mes médicaments. Je peux écrire, choisir une réponse rapide ou utiliser la saisie vocale si mon appareil la prend en charge.

Je n’ai pas besoin de tenir un journal au préalable et je peux laisser les détails facultatifs vides.

Quand j’ai terminé, MORI enregistre mes mots d’origine et me demande l’autorisation d’envoyer les informations de santé sélectionnées pour une traduction par IA. Après mon accord, Gemini les traduit en coréen.

## 4. Le moment clé — vérification du texte original → fiche pour le soignant → PDF

Je vérifie que les informations que j’ai saisies sont correctes. On ne me demande pas de certifier une traduction coréenne que je ne sais pas lire.

J’appuie ensuite sur « Montrer au professionnel de santé ».

C’est le moment le plus important dans MORI : j’ai maintenant un document que je peux montrer à la clinique.

La fiche rassemble la clinique choisie, mes symptômes en coréen, le texte original, mes allergies et mes médicaments. Je peux aussi choisir d’inclure des informations personnelles enregistrées ou des contacts d’urgence.

Je peux montrer cet écran ou enregistrer un PDF. Cet exemple court tient sur une page. Un contenu plus long peut nécessiter des pages supplémentaires.

MORI ne pose pas de diagnostic et ne prend pas de rendez-vous. La fiche précise clairement que la traduction est générée par IA et n’a pas été validée par un professionnel de santé.

## 5. Conclusion — fiche terminée, puis face caméra

Nous avons testé le parcours principal avec des cas fictifs, y compris une véritable traduction avec Gemini et le téléchargement du PDF. La prochaine étape sera de l’évaluer avec davantage d’étudiants internationaux et de professionnels de santé.

Notre objectif est simple : aider les étudiants à passer de « Je ne sais pas où aller ni quoi dire » à « J’ai choisi une clinique et mes symptômes sont prêts à être montrés ».

C’est cela, MORI. Merci.
