
document.addEventListener('DOMContentLoaded', () => {
  const uploadForm = document.getElementById('upload-form');
  const fileInput = document.getElementById('file-input');
  const uploadStatus = document.getElementById('upload-status');
  const gallery = document.getElementById('gallery');

  // --- Función para crear y añadir un item a la galería ---
  const createGalleryItem = (item) => {
    const itemDiv = document.createElement('div');
    itemDiv.className = 'gallery-item';

    let mediaElement;
    if (item.type === 'photo') {
      mediaElement = document.createElement('img');
      mediaElement.src = item.url;
      mediaElement.alt = item.filename;
    } else if (item.type === 'audio') {
      mediaElement = document.createElement('audio');
      mediaElement.controls = true;
      mediaElement.src = item.url;
    }

    const infoDiv = document.createElement('div');
    infoDiv.className = 'item-info';
    infoDiv.textContent = item.filename;

    itemDiv.appendChild(mediaElement);
    itemDiv.appendChild(infoDiv);
    
    return itemDiv;
  };

  // --- Cargar galería al iniciar ---
  const loadGallery = async () => {
    try {
      const response = await fetch('/api/gallery');
      if (!response.ok) throw new Error('No se pudo cargar la galería.');
      
      const items = await response.json();
      gallery.innerHTML = ''; 
      items.forEach(item => {
        const galleryItem = createGalleryItem(item);
        gallery.appendChild(galleryItem);
      });
    } catch (error) {
      console.error('Error cargando la galería:', error);
      gallery.innerHTML = '<p>No se pudieron cargar los archivos.</p>';
    }
  };

  // --- Lógica de subida ---
  uploadForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    if (!fileInput.files.length) {
        uploadStatus.textContent = 'Por favor, selecciona un archivo.';
        return;
    }

    const formData = new FormData();
    formData.append('media', fileInput.files[0]);
    uploadStatus.textContent = 'Subiendo archivo...';
    uploadStatus.style.color = '#333';

    try {
      const response = await fetch('/upload', { method: 'POST', body: formData });
      const newItem = await response.json();

      if (response.ok) {
        uploadStatus.textContent = `¡Éxito! Archivo "${newItem.filename}" subido.`;
        uploadStatus.style.color = 'green';
        
        const galleryItem = createGalleryItem(newItem);
        gallery.prepend(galleryItem);

        uploadForm.reset();
      } else {
        throw new Error(newItem.message || 'Error en la subida.');
      }
    } catch (error) {
      uploadStatus.textContent = `Error: ${error.message}`;
      uploadStatus.style.color = 'red';
    }
  });

  // --- Carga inicial ---
  loadGallery();
});
