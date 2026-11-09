/// Música de `biblia.musica` (com o gênero de `biblia.musica_genero`), como devolvida por
/// `GET /v1/musica/aleatoria`. Inspiração e links das plataformas podem vir nulos.
class MusicaModel {
  const MusicaModel({
    required this.musiId,
    required this.musiNome,
    required this.musiArtista,
    required this.mgenNome,
    this.musiInspiracao,
    this.musiSpotify,
    this.musiDeezer,
    this.musiAppleMusic,
  });

  final int musiId;
  final String musiNome;
  final String musiArtista;
  final String mgenNome;
  final String? musiInspiracao;
  final String? musiSpotify;
  final String? musiDeezer;
  final String? musiAppleMusic;

  factory MusicaModel.fromJson(Map<String, dynamic> json) => MusicaModel(
    musiId: ((json['musiId'] ?? json['musi_id']) as num).toInt(),
    musiNome: (json['musiNome'] ?? json['musi_nome']) as String,
    musiArtista: (json['musiArtista'] ?? json['musi_artista']) as String,
    mgenNome: (json['mgenNome'] ?? json['mgen_nome']) as String,
    musiInspiracao: (json['musiInspiracao'] ?? json['musi_inspiracao']) as String?,
    musiSpotify: (json['musiSpotify'] ?? json['musi_spotify']) as String?,
    musiDeezer: (json['musiDeezer'] ?? json['musi_deezer']) as String?,
    musiAppleMusic: (json['musiAppleMusic'] ?? json['musi_apple_music']) as String?,
  );

  Map<String, dynamic> toJson() => {
    'musiId': musiId,
    'musiNome': musiNome,
    'musiArtista': musiArtista,
    'mgenNome': mgenNome,
    'musiInspiracao': musiInspiracao,
    'musiSpotify': musiSpotify,
    'musiDeezer': musiDeezer,
    'musiAppleMusic': musiAppleMusic,
  };
}

/// Plataforma de streaming com link para a música; [icone] é a chave em `IconsMap.mdiIcons`.
enum MusicaPlataforma {
  spotify('Spotify', 'spotify'),
  deezer('Deezer', 'music-circle'),
  appleMusic('Apple Music', 'apple');

  const MusicaPlataforma(this.nome, this.icone);

  /// Nome da marca (não é traduzido).
  final String nome;
  final String icone;
}

/// Link de uma música em uma [MusicaPlataforma].
class MusicaLink {
  const MusicaLink({required this.plataforma, required this.url});

  final MusicaPlataforma plataforma;
  final Uri url;
}
