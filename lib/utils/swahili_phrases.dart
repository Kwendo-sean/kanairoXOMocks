import '../models/moment.dart';

class SwahiliPhrases {
  static const Map<String, List<String>> _phrasesByTag = {
    'event': [
      'Tulifurahi sana',
      'Usiku wa kupendeza',
      'Pamoja daima',
      'Furaha kubwa',
      'Wakati mzuri',
      'Hii ndiyo maisha',
      'Moment za milele',
      'Nairobi inawaka',
      'Ilikuwa bora',
      'Tukafurahia sana',
    ],
    'meetup': [
      'Marafiki wa kweli',
      'Watu wazuri',
      'Squad yangu',
      'Familia ya moyo',
      'Upendo wa kweli',
      'Tukacheka sana',
      'Tunaendelea pamoja',
      'Wenzangu wapendwa',
      'Bondi yetu',
      'Tukakutana tena',
    ],
    'vibe': [
      'Roho inaimba',
      'Hisia za moyo',
      'Siku njema',
      'Maisha ni mazuri',
      'Furaha ndogo ndogo',
      'Kila siku ni zawadi',
      'Wakati wangu',
      'Nairobi yangu',
      'Kupumua tu',
      'Pumzika kidogo',
    ],
  };

  static const List<String> _general = [
    'Kumbukumbu za dhahabu',
    'Picha ya milele',
    'Siku hii haikuwa bure',
    'Muda mzuri umepita',
    'Asante Mungu',
    'Nairobi na wewe',
    'Baraka kubwa',
    'Tuliishi vizuri',
    'Story ya kweli',
    'Naipenda hii',
    'Kumbukumbu njema',
    'Furaha ya moyo',
    'Nairobi mapenzi',
    'Tukiwa pamoja',
    'Saa njema',
  ];

  static String getPhrase(Moment moment) {
    final tag = moment.type.name.toLowerCase();
    final phrases = _phrasesByTag[tag] ?? _general;

    final seed = moment.id.hashCode.abs();
    return phrases[seed % phrases.length];
  }
}
