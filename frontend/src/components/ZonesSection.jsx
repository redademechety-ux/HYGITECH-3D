import React from 'react';
import { MapPin, Clock, Car, CheckCircle } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';

export const ZonesSection = () => {
  const departments = [
    { code: "75", name: "Paris", popular: true },
    { code: "92", name: "Hauts-de-Seine", popular: true },
    { code: "93", name: "Seine-Saint-Denis" },
    { code: "94", name: "Val-de-Marne" },
    { code: "77", name: "Seine-et-Marne" },
    { code: "78", name: "Yvelines" },
    { code: "91", name: "Essonne" },
    { code: "95", name: "Val-d'Oise" }
  ];

  const advantages = [
    {
      icon: <Clock className="w-6 h-6 text-emerald-600" />,
      title: "Intervention Rapide",
      description: "24-48h selon urgence et localisation"
    },
    {
      icon: <Car className="w-6 h-6 text-emerald-600" />,
      title: "Frais de Déplacement Transparents",
      description: "Variables selon distance, précisés dans le devis"
    },
    {
      icon: <MapPin className="w-6 h-6 text-emerald-600" />,
      title: "Connaissance du Terrain",
      description: "Expertise locale pour une intervention adaptée"
    }
  ];

  const popularCities = [
    "Paris", "Malakoff", "Boulogne-Billancourt", "Issy-les-Moulineaux",
    "Vanves", "Montrouge", "Châtillon", "Clamart", "Meudon", "Sèvres",
    "Saint-Cloud", "Neuilly-sur-Seine", "Levallois-Perret", "Clichy",
    "Asnières-sur-Seine", "Courbevoie", "Puteaux", "Nanterre"
  ];

  return (
    <section id="zones" className="py-20 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* En-tête */}
        <div className="text-center mb-16">
          <h2 className="text-3xl lg:text-4xl font-bold text-gray-900 mb-4">
            Zone d'Intervention Île-de-France
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Basés à Malakoff (92), nous intervenons dans tous les départements 
            d'Île-de-France pour vos besoins d'hygiène professionnelle.
          </p>
        </div>

        {/* Départements */}
        <div className="mb-16">
          <h3 className="text-2xl font-bold text-gray-900 text-center mb-8">
            Départements Couverts
          </h3>
          
          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {departments.map((dept, index) => (
              <Card 
                key={index} 
                className={`text-center hover:shadow-lg transition-all duration-300 hover:-translate-y-1 ${
                  dept.popular ? 'ring-2 ring-emerald-200 bg-emerald-50' : ''
                }`}
              >
                <CardContent className="p-6">
                  <div className="text-2xl font-bold text-emerald-600 mb-2">
                    {dept.code}
                  </div>
                  <div className="font-semibold text-gray-900 mb-1">
                    {dept.name}
                  </div>
                  {dept.popular && (
                    <div className="text-xs text-emerald-600 font-medium">
                      Zone prioritaire
                    </div>
                  )}
                </CardContent>
              </Card>
            ))}
          </div>
        </div>

        {/* Avantages */}
        <div className="grid md:grid-cols-3 gap-8 mb-16">
          {advantages.map((advantage, index) => (
            <Card key={index} className="text-center p-6">
              <div className="w-12 h-12 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-4">
                {advantage.icon}
              </div>
              <h4 className="font-semibold text-gray-900 mb-3">{advantage.title}</h4>
              <p className="text-gray-600 text-sm">{advantage.description}</p>
            </Card>
          ))}
        </div>

        {/* Villes populaires */}
        <div className="bg-gradient-to-r from-emerald-50 to-teal-50 rounded-2xl p-8 lg:p-12">
          <div className="text-center mb-8">
            <h3 className="text-2xl font-bold text-gray-900 mb-4">
              Villes d'Intervention Fréquentes
            </h3>
            <p className="text-gray-600">
              Nous intervenons régulièrement dans ces communes, 
              mais notre service couvre toute l'Île-de-France
            </p>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
            {popularCities.map((city, index) => (
              <div 
                key={index}
                className="bg-white rounded-lg p-3 text-center shadow-sm hover:shadow-md transition-shadow"
              >
                <div className="flex items-center justify-center space-x-2">
                  <CheckCircle className="w-3 h-3 text-emerald-600" />
                  <span className="text-sm font-medium text-gray-700">{city}</span>
                </div>
              </div>
            ))}
          </div>

          <div className="text-center mt-8">
            <p className="text-sm text-gray-600 mb-4">
              Votre ville n'est pas listée ? Pas de problème !
            </p>
            <div className="inline-flex items-center px-4 py-2 bg-emerald-600 text-white rounded-lg text-sm font-medium">
              <MapPin className="w-4 h-4 mr-2" />
              Nous intervenons dans toute l'Île-de-France
            </div>
          </div>
        </div>

        {/* Information siège social */}
        <div className="mt-12 text-center">
          <div className="inline-flex items-center space-x-3 bg-white rounded-lg shadow-sm p-6">
            <div className="w-12 h-12 bg-emerald-100 rounded-full flex items-center justify-center">
              <MapPin className="w-6 h-6 text-emerald-600" />
            </div>
            <div className="text-left">
              <h4 className="font-semibold text-gray-900">Notre siège social</h4>
              <p className="text-gray-600 text-sm">
                122 Boulevard Gabriel Péri, 92240 MALAKOFF
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};