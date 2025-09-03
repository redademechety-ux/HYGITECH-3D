import React, { useState } from 'react';
import { Phone, Mail, MapPin, Clock, Send, CheckCircle } from 'lucide-react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Textarea } from './ui/textarea';
import { useToast } from '../hooks/use-toast';
import { submitContactForm } from '../data/mock';

export const ContactSection = () => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    subject: '',
    message: '',
    hasPets: false,
    hasVulnerablePeople: false
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { toast } = useToast();

  const handleInputChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: type === 'checkbox' ? checked : value
    }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      const result = await submitContactForm(formData);
      if (result.success) {
        toast({
          title: "Demande envoyée !",
          description: result.message,
        });
        // Reset form
        setFormData({
          name: '',
          email: '',
          phone: '',
          subject: '',
          message: '',
          hasPets: false,
          hasVulnerablePeople: false
        });
      }
    } catch (error) {
      toast({
        title: "Erreur",
        description: "Une erreur s'est produite. Veuillez réessayer.",
        variant: "destructive",
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const contactInfo = [
    {
      icon: <Phone className="w-6 h-6 text-emerald-600" />,
      title: "Téléphone",
      details: [
        { label: "Portable", value: "06 68 06 29 70" },
        { label: "Fixe", value: "01 81 89 28 86" }
      ]
    },
    {
      icon: <Mail className="w-6 h-6 text-emerald-600" />,
      title: "Email",
      details: [
        { label: "Contact", value: "contact@hygitech-3d.com" }
      ]
    },
    {
      icon: <MapPin className="w-6 h-6 text-emerald-600" />,
      title: "Adresse",
      details: [
        { label: "", value: "122 Boulevard Gabriel Péri" },
        { label: "", value: "92240 MALAKOFF" }
      ]
    },
    {
      icon: <Clock className="w-6 h-6 text-emerald-600" />,
      title: "Zone d'intervention",
      details: [
        { label: "", value: "Toute l'Île-de-France" },
        { label: "Délai", value: "Intervention 24-48h" }
      ]
    }
  ];

  return (
    <section id="contact" className="py-20 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* En-tête */}
        <div className="text-center mb-16">
          <h2 className="text-3xl lg:text-4xl font-bold text-gray-900 mb-4">
            Contactez-Nous
          </h2>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto">
            Obtenez un devis gratuit et personnalisé. Notre équipe vous répond rapidement 
            pour résoudre vos problèmes d'hygiène.
          </p>
        </div>

        <div className="grid lg:grid-cols-2 gap-12">
          {/* Informations de contact */}
          <div className="space-y-8">
            <div>
              <h3 className="text-2xl font-bold text-gray-900 mb-6">
                Nos Coordonnées
              </h3>
              
              <div className="grid gap-6">
                {contactInfo.map((info, index) => (
                  <Card key={index} className="p-6">
                    <div className="flex items-start space-x-4">
                      <div className="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-center flex-shrink-0">
                        {info.icon}
                      </div>
                      <div>
                        <h4 className="font-semibold text-gray-900 mb-2">{info.title}</h4>
                        {info.details.map((detail, idx) => (
                          <p key={idx} className="text-gray-600">
                            {detail.label && <span className="font-medium">{detail.label}: </span>}
                            {detail.value}
                          </p>
                        ))}
                      </div>
                    </div>
                  </Card>
                ))}
              </div>
            </div>

            {/* Appel à l'action rapide */}
            <div className="bg-gradient-to-r from-emerald-50 to-teal-50 rounded-xl p-6">
              <h4 className="font-semibold text-gray-900 mb-3">Urgence ?</h4>
              <p className="text-gray-600 mb-4">
                Pour une intervention d'urgence, appelez-nous directement :
              </p>
              <div className="flex flex-col sm:flex-row gap-3">
                <a
                  href="tel:0668062970"
                  className="flex items-center justify-center bg-emerald-600 hover:bg-emerald-700 text-white px-6 py-3 rounded-lg font-medium transition-colors"
                >
                  <Phone className="w-4 h-4 mr-2" />
                  06 68 06 29 70
                </a>
                <a
                  href="https://wa.me/33668062970"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center justify-center bg-green-600 hover:bg-green-700 text-white px-6 py-3 rounded-lg font-medium transition-colors"
                >
                  WhatsApp
                </a>
              </div>
            </div>
          </div>

          {/* Formulaire de contact */}
          <Card>
            <CardHeader>
              <CardTitle>Demande de Devis Gratuit</CardTitle>
              <CardDescription>
                Décrivez votre situation et nous vous recontacterons sous 24h
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="grid sm:grid-cols-2 gap-4">
                  <div>
                    <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-2">
                      Nom complet *
                    </label>
                    <Input
                      id="name"
                      name="name"
                      type="text"
                      required
                      value={formData.name}
                      onChange={handleInputChange}
                      placeholder="Votre nom"
                    />
                  </div>
                  <div>
                    <label htmlFor="phone" className="block text-sm font-medium text-gray-700 mb-2">
                      Téléphone *
                    </label>
                    <Input
                      id="phone"
                      name="phone"
                      type="tel"
                      required
                      value={formData.phone}
                      onChange={handleInputChange}
                      placeholder="06 XX XX XX XX"
                    />
                  </div>
                </div>

                <div>
                  <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                    Email *
                  </label>
                  <Input
                    id="email"
                    name="email"
                    type="email"
                    required
                    value={formData.email}
                    onChange={handleInputChange}
                    placeholder="votre@email.com"
                  />
                </div>

                <div>
                  <label htmlFor="subject" className="block text-sm font-medium text-gray-700 mb-2">
                    Type d'intervention *
                  </label>
                  <select
                    id="subject"
                    name="subject"
                    required
                    value={formData.subject}
                    onChange={handleInputChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
                  >
                    <option value="">Sélectionnez un service</option>
                    <option value="desinfection">Désinfection</option>
                    <option value="desinsectisation">Désinsectisation</option>
                    <option value="deratisation">Dératisation</option>
                    <option value="nettoyage-chantier">Nettoyage fin de chantier</option>
                    <option value="autre">Autre / Plusieurs services</option>
                  </select>
                </div>

                <div>
                  <label htmlFor="message" className="block text-sm font-medium text-gray-700 mb-2">
                    Description de votre problème *
                  </label>
                  <Textarea
                    id="message"
                    name="message"
                    required
                    value={formData.message}
                    onChange={handleInputChange}
                    placeholder="Décrivez votre situation, la surface à traiter, la localisation..."
                    rows={4}
                  />
                </div>

                {/* Précautions importantes */}
                <div className="space-y-3">
                  <p className="text-sm font-medium text-gray-700">Précautions importantes :</p>
                  
                  <div className="flex items-center space-x-3">
                    <input
                      type="checkbox"
                      id="hasPets"
                      name="hasPets"
                      checked={formData.hasPets}
                      onChange={handleInputChange}
                      className="w-4 h-4 text-emerald-600 border-gray-300 rounded focus:ring-emerald-500"
                    />
                    <label htmlFor="hasPets" className="text-sm text-gray-700">
                      Présence d'animaux de compagnie
                    </label>
                  </div>
                  
                  <div className="flex items-center space-x-3">
                    <input
                      type="checkbox"
                      id="hasVulnerablePeople"
                      name="hasVulnerablePeople"
                      checked={formData.hasVulnerablePeople}
                      onChange={handleInputChange}
                      className="w-4 h-4 text-emerald-600 border-gray-300 rounded focus:ring-emerald-500"
                    />
                    <label htmlFor="hasVulnerablePeople" className="text-sm text-gray-700">
                      Présence de personnes vulnérables (enfants, femmes enceintes, personnes âgées)
                    </label>
                  </div>
                </div>

                <Button
                  type="submit"
                  disabled={isSubmitting}
                  className="w-full bg-emerald-600 hover:bg-emerald-700 text-white py-3"
                >
                  {isSubmitting ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                      Envoi en cours...
                    </>
                  ) : (
                    <>
                      <Send className="w-4 h-4 mr-2" />
                      Envoyer ma demande
                    </>
                  )}
                </Button>
              </form>
            </CardContent>
          </Card>
        </div>
      </div>
    </section>
  );
};