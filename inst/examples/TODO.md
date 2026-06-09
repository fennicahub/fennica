TODO
==========

Moving one field at a time from main_in_transfer.R to main.R


### Technical
- change melinda_id name to id everywhere because it is not technically melinda id now

- Use feather instead of Rds?

- Move many key functions from funcs.R to R/ folder and package

- Paikkatiedot: Billnäs -> Karjaa?


- Gender: putsattu top-20 female mukaan. (F + K). Gender-mäppien
  viimeistely. After Krakow.

- Apply publisher polishing also for the corporate field (at least in Fennica)?

- Vieläkin näyttäs olevan negatiivisia pagecountteja

- Use corporate field for NA publishers ?
   #if ("corporate" %in% names(df.orig)) {
   #  message("Augmenting missing publisher entries with the corporate field")
   #  inds <- which(is.na(df.orig$publisher))
   #  df.orig$publisher[inds] <- df.orig$corporate[inds]
   #}

- Lisää 6to kokoarviot tauluihin

- Single/MultiVol/Issue erottelut tulee ESTn nojalla mutta
  kesken. Pitäiskö tehdä erikseen Fennicalle ym vai ei

- KK:lta saatu ~/proj/2014-Aatelouhinta/Sanastoja.doc - tietokantoja
  joita voitaisiin käyttää suomalaisten paikannimien, henkilönimien
  ym. validointiin.

- Found the following files with duplicate lower-cased file names:
  inst/examples/output.tables/city_Altdorf.csv
  inst/examples/output.tables/city_Berliini.csv
  etc..

- Synonyymitaulujen haku on mahd. pitkälle automatisoitu
  stringmatchingillä. Voidaanko tätä hyödyntää lisää?


# CERL ?
# All ESTC fiels 100a|100d|240n|245a|260a|260b|260c|300a|300c|310a|362a|650a|650y,651y|650z,651a,651z
# All Fennica fields 041a|041h|100a|100d|240a|245a|245b|260a|260b|260c|300a|300b|300c|300e|310a|362a|500a|502a|502c|502d|510a|510c|650a|651a|710a|720a|785t|852a  
# All Kungliga fields 008lang|100a|100d|110a|240a|245a|245b|245c|260a|260b|260c|260e|260f|300a|300b|300c|300e|310a|362a|440a|440v|500a|502a|502c|502d|510a|510c|650a|650x|650y|650z|651a|700a|700d|710a|720a|740a|772c|772d|772t|785t|852a|852j|852z|866x|900a|900d|900u|976a|976b




### Analyses

- Self-publishing in time. Huom julkaisjakentän eri kirjoitusasuja;
  tekijänimille ei välttämättä osata yhdistää kirjoittajakentän kanssa

- ESTC Suomessa / Ruotsissa ? (alkaa lähteä homma vähän käsistä jos
  vielä ESTC:ä ängetään tähän samaa kässäriin tällä aikataululla eli
  jättäisin pois)


Tärkein tehtävä tutkia pystytäänkö julkaisemiseen liittyvästä
Fennica-datasta erottelemaan jotain selkeitä trendejä suomalaisesta
tiedontuotannosta aikavälillä 1640-1828, pääfokus julkaisijat.

* Yleiset trendit:

Miten paperinkulutus suhtautuu dokumenttien määrään? Löydetäänkö
ajankohtia jolloin on poikkeuksellista kasvua / laskua tms. Esim
top-10 julkaisupaikat. kirjan nousuun mediana (paperinkulutus /
dokumentti, miten yli 50 sivuiset dokumentit yleistyvät ajassa /
voidaanko tässä nähdä jotain paikallisia eroja?

* Julkaisijatrendit:

Julkaisijoista verkostoanalyysi. Keskeisimmät “nodet” siihen miten
julkaisijakenttä muuttuu ajassa. Auktorit, valtioasiakirjat,
yliopisto, muut julkaisijat (ainakin) kategoroina joiden ympärille
verkostoanalyysi voisi syntyä (valtionasiakirjojen ja
yliopisto-aineiston luokittelu voisi mahdollisesti syntyä asiasanojen
ja otsikoiden luokittelun avulla).

Julkaisijoiden ilmentyminen kartalle paperinkulutusvoluumi huomioiden:
julkaisutoiminnan leviäminen ja kasvu ajassa eri
paikkakunnilla. Pääpaino erityisesti sillä kun julkaisijakartalle
tulee uusia toimijoita! Toimijoita voisi myös yrittää luokitella
suhteellisesti (“iso”, “keskikokoinen”, “pieni”) liittyen
vuosittaiseen julkaisuvoluumiin jota mitataan niin julkaisujen määrän
kuin myös paperinkulutusvoluumin suhteen. Analyysia voisi tästä tehdä
sitten näiden luokkien kehityksen mukaan.

Julkaisijoita voisi myös luokitella eniten käytettyjen asiasanojen
mukaan. Näiden perusteella voidaan varmaankin erotella
yliopistojulkaiseminen, asiakirja/asetusjulkaiseminen,
kirjajulkaiseminen?

Turku vs. muu Suomi (sillä kytköksellä että kun Kungliga aineisto
tulee mukaan analyysiin, niin Turku osana ruotsalaista
yliopistojärjestelmää (ml. Tarto) muuttuu tärkeäksi). Eli Turun
erityistapaus analysoidaan tarkkaan, kuinka paljon yliopistoon
liittyvää julkaisutoimintaa, kuinka paljon julkaisijoita, miten
julkaisijoiden verkosto muodostuu Turussa, miten eri julkaisijoita
Turussa voitaisiin luokitella (julkaiseeko joku paperinkulutukseltaan
vain pieniä dokumentteja, julkaiseeko joku painotalo huomattavasti
enemmän kuin toiset), tarkoituksena yleisten historiallisten trendien
löytäminen.

Isojen toimijoiden kohdalla sitten tarkempaa analyysiä jossa pyritään
vertailemaan eri julkaisijoita ja niiden toimintaperiaatteita: “Siinä
missä Londicer 1700-luvun Vaasassa näyttää aina julkaisseen asetukset
jonkinlaisena kokoomapainoksena, mutta Frenckellin kirjapainosta ne
tuli yksitellen. Siten Frenckellin julkaisemien niteiden määrä saattaa
näyttää suurelta verrattuna Londiceriin, mutta itse asiassa
sisältömäärä on sama”. → Tämä hypoteesi me voidaan
todentaa/tarkistaa/korjata kun mukana on paperinkulutus!



