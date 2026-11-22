@tool
class_name ShapeObject
extends WordEntry
## Un objeto cotidiano con su forma (p. ej. una pelota → círculo), para
## relacionar las figuras con las cosas del entorno.

@export var shape: ShapeGeometry.Shape = ShapeGeometry.Shape.CIRCLE


## "la pelota", "el reloj", "los banderines".
func definite() -> String:
	var articles := {"un": "el", "una": "la", "unos": "los", "unas": "las"}
	return "%s %s" % [articles.get(article, "el"), word]
