docker run -u $(id -u):$(id -g) -v .:/data -w /data apollo994/geneidtrainerdocker:latest  -species species3 -gff sample1kCDS.gff -fastas reference.fna -results ./results/ -reduced no
