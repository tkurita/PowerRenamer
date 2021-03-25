/*
1.0.5 -- 2016-10-27
  * improved position of expandIcon
  * when original size is smaller than natural size, pupup-image is enabled
    even if the image is not reduced.
1.0.4 -- 2016-10-26
  * if 'shrinked' is appended of class of img tag, it is considered that 
    the size of image has been already shrinked.
  * fixed position of expaned image.
1.0.3 -- 2016-09-01
  * Support retina display. If a filename is ends with '@2x', 
    the size of the popuped image will be half of dimension of the image file.
1.0.2 -- 2012-05-22
  * fixed error when resizeShrinkPopupImages is called before setupShrinkPopupImages.
1.0.1 -- 2012-05-01
  * resize image when the window is resezed.
1.0 -- 2012-04-03
  * first implementation
*/

function plog(msg) {
  document.write('<p>'+msg+'</p>');
}

function PopupImageController(image) {
  this.targetImage = image;
  this.originalHeight = image.height;
  this.originalWidth = image.width;
  image.parentNode.style.position = 'relative';

  var icon_src = document.getElementById('expand-icon-image');
  if (icon_src) {
    this.expandIcon = document.createElement('img');
    with(this.expandIcon) {
      src = icon_src.href;
      style.position = "absolute";
      style.opacity = "0.7";
      style.visibility = 'hidden';
    }
    this.targetImage.parentNode.appendChild(this.expandIcon);
  }
  this.disablePopup = true;
  this.setupExpandImage();
  return this;
}

PopupImageController.initOverlay = function() {
  if (!this.overlay) {
    this.overlay = document.createElement('div');
    with(this.overlay) {
      style.position = "fixed";
      style.left = "0";
      style.top = "0";
      style.opacity = "0.7";
      style.backgroundColor ="black";
      style.width = "100%";
      style.height = "100%";
      style.fontSize = "14px";
      style.textAlign = 'center';
      style.color = 'black';
      style.zIndex = 3;
      appendChild(document.createTextNode("Loading image ..."));
      addEventListener('click', 
                       function() {PopupImageController.closePopup()}, true);
    }
  }
}

PopupImageController.closePopup = function() {
    document.body.removeChild(this.currentImage);
    document.body.removeChild(this.overlay);
}

PopupImageController.prototype = {
  showIcon : function() {
    if (this.disablePopup) {return};
    var parent_width = this.targetImage.width;
    var parent_height = this.targetImage.height;
    with(this.expandIcon) {
      style.left = this.targetImage.offsetLeft
        + Math.floor((parent_width - width)/2) + 'px';
      style.top = this.targetImage.offsetTop
        + Math.floor((parent_height - height)/2) + 'px';
    }
    var self = this;
    this.expandIcon.addEventListener('click', 
                                     function() {self.clickIcon()}, true);

    this.expandIcon.style.visibility = 'visible';
  },
  
  hideIcon : function(e) {
    var rect = e.currentTarget.getClientRects()[0];
    if(    e.clientX >= rect.left
           && e.clientX <= rect.right
           && e.clientY >= rect.top
           && e.clientY <= rect.bottom
      ){ return }
    this.expandIcon.style.visibility = 'hidden';
  },
  
  clickIcon : function() {
    if (this.disablePopup) {return};
    this.popupImage();
  },
  
  setImagePosition : function() {
    w_width = window.innerWidth;
    if (this.expandImage.width > w_width) {
      this.expandImage.style.left = window.pageXOffset+10+'px';
    } else {
      this.expandImage.style.left = Math.floor(window.pageXOffset
                                               +(w_width-this.expandImage.width)/2) + 'px';
    }

    w_height = window.innerHeight;
    if (this.expandImage.height > w_height) {
      this.expandImage.style.top = window.pageYOffset+10+'px';
    } else {
      this.expandImage.style.top = Math.floor(window.pageYOffset
                                              +(w_height-this.expandImage.height)/2) + 'px';
    }
  },
  
  onExpandImageLoad : function() {
    this.setImagePosition();
    this.expandImage.style.visibility = 'visible';
  },
  
  setupExpandImage : function () {
    this.expandImage = document.createElement('img');
    var re = /.+\/(.+?)@2x\.[a-z]+([\?#;].*)?$/;
    with (this.expandImage) {
      src = this.targetImage.src;
      style.position = 'absolute';
      style.margin = '0';
      style.visibility = 'hidden';
      style.zIndex = 3;
      var self = this;
      addEventListener('click',
                       function(){ PopupImageController.closePopup() } ,
                       true);
      addEventListener('load',
                       function(){ self.onExpandImageLoad() }, true);
      if (re.test(src)) {
        height = height/2;
        width = width/2;
      }
    }
  },
  
  popupImage : function() {
    if (this.disablePopup) {return}
    PopupImageController.initOverlay();
    if (!this.expandImage) {
      PopupImageController.overlay.style.color = 'white';
      this.setupExpandImage();
    } else {
      this.setImagePosition();
      this.expandImage.style.visible = 'visible';
    }
    document.body.appendChild(PopupImageController.overlay);
    document.body.appendChild(this.expandImage);
    PopupImageController.currentImage = this.expandImage;
  },

  updateOriginalImageSize : function() {
    var w = this.targetImage.parentNode.clientWidth;
    var scale = w/this.originalWidth;
    if (this.originalWidth > w || this.originalWidth > this.targetImage.width) {
      if (w > this.originalWidth) {
        w = this.originalWidth;
        scale = 1;
      }
      this.targetImage.width = w;
      this.targetImage.height = scale*this.originalHeight;
    }
    
    if (this.expandImage.width > this.targetImage.width) {
      this.disablePopup = false;
    } else {
      this.disablePopup = true;
    }
  }
};

function setupImage(img) {
  //var w_width = img.parentNode.clientWidth;
  img.controller = new PopupImageController(img);
  if (img.controller.expandIcon) {
    img.addEventListener('mouseover', 
                         function() {this.controller.showIcon()}, false);
    img.addEventListener('mouseout', 
                         function(e) {this.controller.hideIcon(e)}, false);
  }
  img.addEventListener('click', 
                       function() {this.controller.popupImage()}, true);

  img.controller.updateOriginalImageSize();
}

function setupShrinkPopupImages() {
  var img_elems = document.getElementsByClassName('shrink-popup');
  for (n=0; n < img_elems.length; n++) {
    var img = img_elems[n];
    setupImage(img);
  }
  return true;
}

function resizeShrinkPopupImages() {
  var img_elems = document.getElementsByClassName('shrink-popup');
  for (n=0; n < img_elems.length; n++) {
    var img = img_elems[n];
    img.controller.updateOriginalImageSize();
  }
  return true;
}

window.addEventListener("load", setupShrinkPopupImages, true);
window.addEventListener("resize", resizeShrinkPopupImages, false);
