import React, { useState, useEffect } from 'react';
import { MessageCircle, X } from 'lucide-react';

export const WhatsAppButton = () => {
  const [isVisible, setIsVisible] = useState(true);
  const [isExpanded, setIsExpanded] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      // Le bouton reste toujours visible selon les spécifications
      setIsVisible(true);
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const openWhatsApp = () => {
    // Numéro WhatsApp de l'entreprise
    const phoneNumber = '33668062970'; // Format international sans le +
    const message = encodeURIComponent(
      'Bonjour, je souhaite obtenir un devis pour vos services d\'hygiène (désinfection, désinsectisation, dératisation).'
    );
    const whatsappUrl = `https://wa.me/${phoneNumber}?text=${message}`;
    window.open(whatsappUrl, '_blank');
  };

  if (!isVisible) return null;

  return (
    <div className="fixed bottom-6 right-6 z-50">
      {/* Bulle de message */}
      {isExpanded && (
        <div className="absolute bottom-16 right-0 mb-2 bg-white rounded-lg shadow-lg border p-4 w-64 animate-in slide-in-from-bottom-2">
          <button
            onClick={() => setIsExpanded(false)}
            className="absolute top-2 right-2 text-gray-400 hover:text-gray-600"
          >
            <X className="w-4 h-4" />
          </button>
          <div className="pr-4">
            <h4 className="font-semibold text-gray-900 mb-2">
              Besoin d'aide ?
            </h4>
            <p className="text-sm text-gray-600 mb-3">
              Contactez-nous directement sur WhatsApp pour un devis gratuit !
            </p>
            <button
              onClick={openWhatsApp}
              className="w-full bg-green-500 hover:bg-green-600 text-white py-2 px-4 rounded-lg text-sm font-medium transition-colors"
            >
              Démarrer la conversation
            </button>
          </div>
        </div>
      )}

      {/* Bouton principal */}
      <div className="relative">
        <button
          onClick={() => setIsExpanded(!isExpanded)}
          className="bg-green-500 hover:bg-green-600 text-white rounded-full w-14 h-14 flex items-center justify-center shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-110 animate-pulse"
          aria-label="Contacter sur WhatsApp"
        >
          <MessageCircle className="w-6 h-6" />
        </button>
        
        {/* Badge de notification */}
        <div className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center font-bold">
          1
        </div>
      </div>
    </div>
  );
};