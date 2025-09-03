import React from 'react';
import { Bug, Rat, Droplets, HardHat, Building, Home, Store, Trees } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';

export const ServicesSection = () => {
  const services = [
    {
      icon: <Droplets className="w-8 h-8 text-blue-600" />,
      title: "Désinfection",
      description: "Élimination des virus, bactéries et germes pathogènes",
      details: ["Surfaces et équipements", "Espaces de travail", "Véhicules", "Locaux commerciaux"]
    },
    {
      icon: <Bug className="w-8 h-8 text-red-600" />,
      title: "Désinsectisation",
      description: "Traitement contre tous types d'insectes nuisibles",
      details: ["Fourmis, cafards", "Puces, punaises", "Guêpes, frelons", "Mites alimentaires"]
    },
    {
      icon: <Rat className="w-8 h-8 text-gray-600" />,
      title: "Dératisation",
      description: "Élimination et prévention des rongeurs",
      details: ["Rats et souris", "Mulots", "Pose de pièges", "Bouchage des accès"]
    },
    {
      icon: <HardHat className="w-8 h-8 text-orange-600" />,
      title: "Nettoyage Fin de Chantier",
      description: "Nettoyage spécialisé après travaux de construction",
      details: ["Évacuation gravats", "Nettoyage poussières", "Remise en état", "Livraison propre"]
    }
  ];

  const interventionTypes = [
    {
      icon: <Building className="w-6 h-6 text-emerald-600" />,
      title: "Entreprises & Bureaux",
      description: "Usines, entrepôts, bureaux, locaux commerciaux"
    },
    {
      icon: <Home className="w-6 h-6 text-emerald-600" />,
      title: "Particuliers",
      description: "Maisons, appartements, résidences"
    },
    {
      icon: <Store className="w-6 h-6 text-emerald-600" />,
      title: "Commerces",
      description: "Boulangeries, cafés, restaurants, magasins"
    },
    {
      icon: <Trees className="w-6 h-6 text-emerald-600" />,
      title: "Espaces Publics",
      description: "Parcs, jardins publics, collectivités"
    }
  ];

  return (
    <section id="services" className="py-20 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* En-tête */}
        <div className="text-center mb-16">
          <h2 className="text-3xl lg:text-4xl font-bold text-gray-900 mb-4">
            Nos Services d'Hygiène Professionnels
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Des solutions complètes adaptées à chaque environnement et situation. 
            Intervention rapide avec des produits certifiés et respectueux de l'environnement.
          </p>
        </div>

        {/* Services principaux */}
        <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6 mb-16">
          {services.map((service, index) => (
            <Card key={index} className="group hover:shadow-lg transition-all duration-300 hover:-translate-y-1">
              <CardHeader className="text-center pb-4">
                <div className="w-16 h-16 mx-auto mb-4 bg-gray-50 rounded-full flex items-center justify-center group-hover:bg-emerald-50 transition-colors">
                  {service.icon}
                </div>
                <CardTitle className="text-xl text-gray-900">{service.title}</CardTitle>
                <CardDescription className="text-gray-600">
                  {service.description}
                </CardDescription>
              </CardHeader>
              <CardContent>
                <ul className="space-y-2">
                  {service.details.map((detail, idx) => (
                    <li key={idx} className="text-sm text-gray-600 flex items-center">
                      <div className="w-1.5 h-1.5 bg-emerald-600 rounded-full mr-3 flex-shrink-0"></div>
                      {detail}
                    </li>
                  ))}
                </ul>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Types d'intervention */}
        <div className="bg-gradient-to-r from-emerald-50 to-teal-50 rounded-2xl p-8 lg:p-12">
          <div className="text-center mb-12">
            <h3 className="text-2xl lg:text-3xl font-bold text-gray-900 mb-4">
              Nous Intervenons Partout
            </h3>
            <p className="text-lg text-gray-600">
              Quel que soit votre secteur d'activité ou type de local
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {interventionTypes.map((type, index) => (
              <div key={index} className="bg-white rounded-xl p-6 text-center shadow-sm hover:shadow-md transition-shadow">
                <div className="w-12 h-12 mx-auto mb-4 bg-emerald-100 rounded-full flex items-center justify-center">
                  {type.icon}
                </div>
                <h4 className="font-semibold text-gray-900 mb-2">{type.title}</h4>
                <p className="text-sm text-gray-600">{type.description}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Précautions importantes */}
        <div className="mt-12 bg-yellow-50 border border-yellow-200 rounded-lg p-6">
          <h4 className="font-semibold text-yellow-800 mb-3 flex items-center">
            <span className="w-2 h-2 bg-yellow-400 rounded-full mr-3"></span>
            Précautions Importantes
          </h4>
          <p className="text-yellow-700">
            Avant notre intervention, merci de nous signaler la présence d'animaux de compagnie 
            ou de personnes vulnérables (enfants, femmes enceintes, personnes âgées) afin d'adapter 
            nos méthodes et produits en conséquence.
          </p>
        </div>
      </div>
    </section>
  );
};