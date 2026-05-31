# MeetSpace - dokumentacija sistema preporuke

## 1. Opis sistema

MeetSpace je aplikacija za pregled i rezervaciju prostora za rad, sastanke, edukacije i događaje. U okviru aplikacije implementiran je sistem preporuke čiji je cilj da korisnicima predloži prostore koji odgovaraju njihovim interesima i prethodnim aktivnostima.

Sistem preporuke olakšava pronalazak relevantnih prostora bez potrebe da korisnik ručno pregleda cjelokupnu ponudu.

## 2. Korišteni pristup

Za generisanje personalizovanih preporuka koristi se **Item-based Collaborative Filtering** algoritam.

Ovaj pristup analizira interakcije korisnika sa prostorima i na osnovu njih izračunava sličnost između prostora. Sistem zatim korisniku preporučuje prostore slične onima sa kojima je ranije imao interakciju, ali koje još nije koristio.

Primjer: ukoliko je korisnik ranije rezervisao prostor „Sala A“, a drugi korisnici koji koriste „Salu A“ često koriste i „Salu C“, sistem može korisniku preporučiti „Salu C“.

## 3. Interakcije korisnika

Algoritam koristi više vrsta interakcija korisnika sa prostorima:

| Interakcija | Vrijednost |
| --- | ---: |
| Odobrena rezervacija prostora | 3 |
| Dodavanje prostora u favorite | 2 |
| Korisnička ocjena prostora | Vrijednost ocjene od 1 do 5 |

Za svakog korisnika i prostor sabiraju se vrijednosti svih evidentiranih interakcija. Na taj način interakcije koje pokazuju veći nivo zainteresovanosti imaju veći uticaj na rezultate.

Primjer: ako je korisnik rezervisao prostor, dodao ga u favorite i ocijenio ocjenom 5, ukupan rezultat za taj prostor iznosi:

`3 + 2 + 5 = 10`

## 4. Izračunavanje sličnosti prostora

Za izračunavanje sličnosti između prostora koristi se **cosine similarity**.

Za svaki prostor formira se vektor rezultata korisničkih interakcija. Sličnost dva prostora izračunava se na osnovu toga koliko često i u kojoj mjeri isti korisnici ostvaruju interakcije sa oba prostora.

Formula:

`similarity(A, B) = dot(A, B) / (norm(A) * norm(B))`

Veća vrijednost znači da su prostori sličniji na osnovu ponašanja korisnika.

## 5. Generisanje preporuka

Za prijavljenog korisnika sistem:

1. Učitava njegove prethodne interakcije sa prostorima.
2. Izračunava sličnost tih prostora sa drugim prostorima.
3. Isključuje prostore sa kojima je korisnik već imao interakciju.
4. Izračunava rezultat kandidata na osnovu sličnosti i vrijednosti postojećih interakcija.
5. Sortira rezultate opadajuće.
6. Vraća najbolje rangirane prostore.

Za personalizovane preporuke prikazuje se objašnjenje:

`Recommended based on your previous bookings and similar user interactions.`

## 6. Cold-start slučaj

Ako korisnik nema prethodne interakcije ili nije moguće dobiti personalizovane rezultate, koristi se rezervni mehanizam.

Sistem tada prikazuje najbolje ocijenjene prostore na osnovu prosječne vrijednosti recenzija. Za takve preporuke prikazuje se objašnjenje:

`Popular highly-rated space.`

## 7. Evidencija preporuka

Sistem evidentira generisane preporuke u tabeli `RecommendationLogs`.

Za svaku preporuku moguće je pratiti:

| Polje | Opis |
| --- | --- |
| `UserId` | Korisnik kojem je prostor preporučen |
| `SpaceId` | Preporučeni prostor |
| `RecommendedAt` | Datum i vrijeme generisanja preporuke |
| `Clicked` | Da li je korisnik otvorio preporučeni prostor |
| `Booked` | Da li je korisnik rezervisao preporučeni prostor |

Prilikom otvaranja preporučenog prostora ažurira se vrijednost `Clicked`. Prilikom kreiranja rezervacije na osnovu preporuke ažurira se vrijednost `Booked`.

## 8. Prednosti implementiranog pristupa

Item-based Collaborative Filtering pristup omogućava:

- personalizovane preporuke na osnovu stvarnog ponašanja korisnika;
- kombinovanje implicitnog feedbacka, kao što su rezervacije i favoriti;
- korištenje eksplicitnog feedbacka kroz ocjene;
- preporučivanje prostora koje korisnik ranije nije pregledao;
- rezervni prikaz najbolje ocijenjenih prostora za nove korisnike.

## 9. Tehnička implementacija

Sistem preporuke implementiran je u servisnom sloju backend aplikacije:

`MeetSpaceBackend/MeetSpace.Services/Services/RecommendationService.cs`

Servis koristi Entity Framework Core za učitavanje potrebnih podataka iz baze i AutoMapper za mapiranje prostora u response DTO objekte.

Podaci se klijentskoj aplikaciji vraćaju kao lista `SpaceResponse` objekata sa informacijama o prostoru, slikama, lokaciji i razlogom preporuke.